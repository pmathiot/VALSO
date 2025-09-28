import os
import numpy as np
import glob
import yaml
import xarray as xr
import pandas as pd
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
#import matplotlib.ticker as ticker
import warnings
warnings.filterwarnings(
    "ignore",
    category=RuntimeWarning,
    message="Converting a CFTimeIndex.*noleap.*"
)

# ===================== CLASSES =====================
class Run:
    """
    Represents the style and data for a specific run.
    """

    def __str__(self):
        return f'    Run(runid={self.runid}, name={self.name}, line={self.line}, color={self.color}, dir={self.dir})'

    def __init__(self, cdir, runid, name, line="-", color="black"):
        """
        Initializes a Run object.

        Args:
            runid (str): Identifier for the run.
            name (str): Name of the run.
            line (str): Line style for plotting.
            color (str): Color for plotting.
        """
        self.runid = runid
        self.name = name
        self.line = line
        self.color = color
        self.dir = os.path.join(cdir, self.runid)
        self.ts = {}

    def load_ts(self, plots):
        """
        Loads time series data for the run using a Plot object.

        Args:
            plot (Plot): Plot configuration object.

        Returns:
            pd.DataFrame: Time series data.
        """
        for plot in plots:
            if plot.type == "TS":
                file_pattern = plot.file_pattern
                var = plot.var
                sf = plot.sf
                files = glob.glob(os.path.join(self.dir, file_pattern))
                print(plot)
                if not files:
                    raise FileNotFoundError(f'No files match {file_pattern} in {self.dir}')

                # opne data
                try:
                    ctime = 'time_centered'
                    ds=xr.open_mfdataset(files, parallel=True, concat_dim='time_counter',combine='nested').sortby(ctime)
                except:
                    ctime = 'time_counter'
                    ds=xr.open_mfdataset(files, parallel=True, concat_dim='time_counter',combine='nested').sortby(ctime)

                # build data array
                da=xr.DataArray(ds[var].values.squeeze()*sf, [(ctime, ds[ctime].values)], name=self.name)

                # manage time
                try:
                    da[ctime] = pd.to_datetime(da.indexes[ctime])
                except:
                    da[ctime] = da.indexes[ctime].to_datetimeindex()

                self.ts[var] = da.to_dataframe(name=self.name)

        return self.ts

    def plot_ts(self, ax, plot):
        """
        Plots the time series data on the given axis.

        Args:
            ax (matplotlib.axes.Axes): Axis to plot on.
            var (str): Variable to plot.

        Raises:
            ValueError: If time series data is not loaded.
        """
        if self.ts is None:
            raise ValueError(f"Time series not loaded for run {self.runid}")
        self.ts[plot.var].plot(ax=ax, legend=False, label=self.name, linestyle=self.line, color=self.color)

        rmin  = self.ts[plot.var].values.min()
        rmax  = self.ts[plot.var].values.max()

        # set x axis
        ax.tick_params(axis='both', labelsize=18)
        if (not plot.time):
            ax.set_xticklabels([])
        else:
            ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y'))
        for lt in ax.get_xticklabels():
            lt.set_ha('center')
        ax.set_xlabel('')

        return rmin, rmax


class Plot:
    """
    Represents a plot configuration.
    """

    def __str__(self):
        return f'        Plot(var={self.var}, file_pattern={self.file_pattern}, sf={self.sf}, title={self.title}, loc={self.row}|{self.col})'

    def __init__(self, data):
        """
        Initializes a Plot object.

        Args:
            data (dict): Dictionary containing plot configuration.
        """
        self.name = data.get("NAME", "UNKNOWN")
        self.var = data.get("VAR", None)
        self.file_pattern = data.get("FILE_PATTERN", None)
        self.sf = data.get("SF", 1.0)
        self.title = data.get("TITLE", "UNKNOWN")
        self.row = data.get("ROW", 1)
        self.col = data.get("COL", 1)
        self.time = data.get("TIME", False)
        self.type = data.get("TYPE", "TS").upper()  # TS = time series, FIG = figure
        self.fig_file = data.get("FIG_FILE", None)
        self.ymin = 99999.0
        self.ymax = -99999.0

    def plot_timeseries(self, ax, runs):
        """
        Plots time series data for the given plot configuration.

        Args:
            ax (matplotlib.axes.Axes): Axis to plot on.
            runs (list): List of Run objects containing time series data.

        Returns:
            tuple: Handles and labels for the legend.
        """
        print(f'    Plot {self.title}')
        rmin = 99999.0
        rmax = -99999.0
        for run in runs:
            zmin, zmax = run.plot_ts(ax, self)
            rmin = min(rmin, zmin)
            rmax = max(rmax, zmax)
        rrange = rmax - rmin
        self.ymin = rmin - 0.05 * rrange
        self.ymax = rmax + 0.05 * rrange

        ax.set_ylim([self.ymin, self.ymax])
        hl, lb = ax.get_legend_handles_labels()
        ax.set_title(self.title, fontsize=24)
        ax.grid(True)
        return hl, lb

    def plot_observation(self, ax, obs):
        """
        Plots observation data for the given plot configuration.

        Args:
            ax (matplotlib.axes.Axes): Axis to plot on.
            obs (Obs): Observation data for the plot.
        """
        if obs is not None:
            plt.errorbar(0, obs.mean, yerr=obs.std, fmt='*', markeredgecolor='k', markersize=8, color='k', linewidth=2)
            ax.set_xlim([-1, 1])
            ax.set_ylim([self.ymin, self.ymax])
            ax.set_xticks([])
            ax.set_yticklabels([])
            ax.grid()


class Obs:
    """
    Represents observation data for a specific variable.

    Attributes:
        mean (float): Mean value of the observation.
        std (float): Standard deviation of the observation.
        ref (str): Reference name for the observation.
    """

    def __init__(self, data):
        """
        Initializes an Obs object by loading data from a YAML file.

        Args:
            data (dict): Dictionary containing observation data.
        """
        self.name = data["NAME"]
        self.mean = data["MEAN"]
        self.std = data["STD"]
        self.ref = data.get("REF", "OBS")

    def __str__(self):
        """
        Returns a string representation of the Obs object.

        Returns:
            str: String representation of the observation data.
        """
        return f"    Obs(name={self.name}, mean={self.mean}, std={self.std}, ref={self.ref})"


class Figure:
    """
    Represents the configuration for a figure, including layout, legend, and subplots.
    """
    def __init__(self, data):
        """
        Initializes a Figure object.

        Args:
            data (dict): Data loaded from figs.yml containing figure configuration.
        """
        self.description = data.get("description", {"NAME": "VALSO"})
        self.legend = data.get("legend", {"NCOL": 3, "AXES": [0.04, 0.01, 0.92, 0.06]})
        self.ts = data.get("ts", {})
        self.map = data.get("map", {})
        self.layout = data.get("layout", {
            "SUBPLOT": [1, 1],
            "SIZE": [10, 8],
            "ADJUST": [0.1, 0.9, 0.1, 0.9, 0.4, 0.4],
            "DPI": 150
        })

    def __str__(self):
        """
        Returns a string representation of the Figure object.

        Returns:
            str: String representation of the figure configuration.
        """
        return (
            f"Figure(description={self.description}, "
            f"legend={self.legend}, "
            f"layout={self.layout}, "
            f"ts_keys={list(self.ts.keys())}, "
            f"map={self.map})"
        )

    def plot_map(self, axs):
        """
        Plots a map image for the given plot configuration.

        Args:
            axs (numpy.ndarray): Array of matplotlib axes.

        Raises:
            FileNotFoundError: If the figure file does not exist.
        """
        img_path = self.map["FILE"]
        if not os.path.exists(img_path):
            raise FileNotFoundError(f"Figure file {img_path} not found")
        img = plt.imread(img_path)

        ax = axs[self.map["POS"][0]-1][self.map["POS"][1]-1]
        ax.set_visible(True)
        ax.imshow(img)
        ax.axis("off")


    def add_legend(self, fig, handles, labels, lvis=True):
        """
        Adds a single legend at the bottom of the figure.

        Args:
            fig (matplotlib.figure.Figure): The figure to add the legend to.
            handles (list): List of legend handles.
            labels (list): List of legend labels.
            lvis (bool): Whether to make legend handles visible.

        Returns:
            matplotlib.axes.Axes: The legend axes for reference.
        """
        lax = fig.add_axes(self.legend["AXES"])
        leg = lax.legend(handles, labels, loc='upper left', ncol=self.legend["NCOL"], fontsize=18, frameon=False)
        for item in leg.legendHandles:
            item.set_visible(lvis)
        lax.set_axis_off()
        return lax

    def generate(self, runids, plots_cfg, style_cfg, obss_cfg, cdir=".", out="output.png"):
        """
        Generates a single figure based on the current configuration.

        Args:
            runids (list): List of run IDs to process.
            plots_cfg (str): Path to the plot configuration file.
            style_cfg (str): Path to the style configuration file.
            obss_cfg (str): Path to the observation configuration file.
            cdir (str): Base directory for data files.
            out (str): Output file name for the generated plot.
        """
        print(f"🔄 Generating figure: {out}")
        plots = load_plots(plots_cfg, self)
        obss = load_obss(obss_cfg, self)
        runs = load_runs(style_cfg, runids, cdir)

        for run in runs:
            print(run)
            run.load_ts(plots)

        # Create subplots
        nrows = self.layout["SUBPLOT"][0]
        ncols = self.layout["SUBPLOT"][1]
        figsize = np.array([self.layout["SIZE"][0] * ncols, self.layout["SIZE"][1] * nrows]) / 25.4  # width, height
        fig, axs = plt.subplots(nrows, ncols, figsize=figsize, squeeze=False)

        for ax in axs.flat:
            ax.set_visible(False)

        # Plot each subplot
        all_handles = []
        all_labels = []
        for plot in plots:
            ax = axs[plot.row - 1][plot.col - 1]
            ax.set_visible(True)

            obs = obss.get(plot.name, None)

            # Plot time series in the main axis
            hl, lb = plot.plot_timeseries(ax, runs)
            all_handles.extend(hl)
            all_labels.extend(lb)

            # Add an additional axis for observations to the right
            x0, y0, width, height = ax.get_position().bounds
            obs_ax = fig.add_axes([x0 + width + 0.02, y0, 0.05, height])  # Adjust the position and width
            obs_ax.set_visible(True)

            # Plot observations in the additional axis
            plot.plot_observation(obs_ax, obs)

        # Finalize and save
        self.plot_map(axs)

        plt.subplots_adjust(left=self.layout["ADJUST"][0],
                            right=self.layout["ADJUST"][1],
                            bottom=self.layout["ADJUST"][2],
                            top=self.layout["ADJUST"][3],
                            wspace=self.layout["ADJUST"][4],
                            hspace=self.layout["ADJUST"][5])

        self.add_legend(fig, all_handles, all_labels, lvis=True)

        plt.savefig(out, dpi=self.layout["DPI"], bbox_inches='tight')
        print(f"✅ Saved {out}")

        plt.close(fig)


# ===================== LOADERS =====================
def load_yaml(file_path):
    """
    Loads a YAML file.

    Args:
        file_path (str): Path to the YAML file.

    Returns:
        dict: Parsed YAML data.
    """
    with open(file_path) as fid:
        return yaml.safe_load(fid)


def load_runs(style_file, runids, cdir):
    """
    Loads run styles from a YAML file.

    Args:
        style_file (str): Path to the style configuration file.
        runids (list): List of run IDs to load.
        cdir (str): Base directory for the runs.

    Returns:
        list: List of Run objects.

    Raises:
        ValueError: If a run ID is not found in the style file.
    """
    data = load_yaml(style_file).get("runs", {})
    runs = []
    for rid in runids:
        if rid not in data:
            raise ValueError(f"RunID {rid} not found in style file")
        info = data[rid]
        runs.append(Run(cdir, rid, info.get("NAME", rid), info.get("LINE", "-"), info.get("COLOR", "black")))
    return runs


def load_plots(plots_file, figure):
    """
    Loads selected plots from plots.yml database based on figs.yml selection.

    Args:
        plots_file (str): Path to the plots.yml file.
        figure (Figure): Figure object containing layout and configuration.

    Returns:
        list: List of Plot objects.

    Raises:
        ValueError: If a plot key is not found in plots.yml or figs.yml is invalid.
    """
    all_plots = load_yaml(plots_file).get("plots", {})
    figs = dict(sorted(figure.ts.items(), key=lambda item: item[0]))  # for easy unit testing
    selected = []

    for key, layout in figs.items():
        if key not in all_plots:
            raise ValueError(f"Plot key {key} not found in plots.yml")
        data = dict(all_plots[key])
        data.update(layout)  # add row/col info
        data["NAME"] = key  # add the plot key as NAME
        selected.append(Plot(data))
    return selected


def load_obss(obss_file, figure):
    """
    Loads observation data from obs.yml based on figs.yml selection.

    Args:
        obss_file (str): Path to the obs.yml file.
        figure (Figure): Figure object containing layout and configuration.

    Returns:
        dict: Dictionary of Obs objects.

    Raises:
        ValueError: If a plot key is not found in obs.yml or figs.yml is invalid.
    """
    all_obss = load_yaml(obss_file).get("obs", {})
    figs = dict(sorted(figure.ts.items(), key=lambda item: item[0]))  # for easy unit testing
    selected = {}

    for key, _ in figs.items():
        if key not in all_obss:
            print(f"⚠️ Warning: Obs key {key} not found in obs.yml")
            continue
        try:
            data = dict(all_obss[key])
            data["NAME"] = key  # add the plot key as NAME
            selected[key] = Obs(data)
        except (FileNotFoundError, KeyError) as e:
            print(f"⚠️ Warning: Failed to load observation for {key}: {e}")
    return selected


def load_figure(figs_file):
    """
    Loads figure configuration from figs.yml.

    Args:
        figs_file (str): Path to the figs.yml file.

    Returns:
        Figure: A Figure object containing the configuration.
    """
    data = load_yaml(figs_file)
    figure = Figure(data)
    return figure


# ===================== MAIN FUNCTION =====================
def main(runids, plots_cfg="plots.yml", figs_cfgs=["figs.yml"], style_cfg="styles.yml", obss_cfg="obs.yml", cdir=".", outs=["valso.png"]):
    """
    Main function to generate plots with additional axes for observations.

    Args:
        runids (list): List of run IDs to process.
        plots_cfg (str): Path to the plot configuration file.
        figs_cfgs (list): List of paths to figs.yml files.
        style_cfg (str): Path to the style configuration file.
        obss_cfg (str): Path to the observation configuration file.
        cdir (str): Base directory for data files.
        outs (list): List of output file names for the generated plots.
    """
    for figs_cfg, out in zip(figs_cfgs, outs):
        # Load data and styles
        figure = load_figure(figs_cfg)
        figure.generate(runids, plots_cfg, style_cfg, obss_cfg, cdir, out)


# ===================== ENTRY POINT =====================
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Generate plots for validation and observation data.")
    parser.add_argument("-runid", nargs="+", required=True, help="List of run IDs to process.")
    parser.add_argument("-plots", default="plots.yml", help="Path to the full plots database.")
    parser.add_argument("-figs", nargs="+", required=True, help="List of paths to figs.yml files.")
    parser.add_argument("-style", default="styles.yml", help="Path to the style configuration file.")
    parser.add_argument("-obs", default="obs.yml", help="Path to the observation configuration file.")
    parser.add_argument("-dir", default=".", help="Base directory for data files.")
    parser.add_argument("-outs", nargs="+", required=True, help="List of output file names for the generated plots.")
    args = parser.parse_args()

    main(
        runids=args.runid,
        plots_cfg=args.plots,
        figs_cfgs=args.figs,
        style_cfg=args.style,
        obss_cfg=args.obs,
        cdir=args.dir,
        outs=args.outs
    )
