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
        return f'Run(runid={self.runid}, name={self.name}, line={self.line}, color={self.color}, dir={self.dir})'

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

        # set x axis
        ax.tick_params(axis='both', labelsize=18)
        if (not plot.time):
            ax.set_xticklabels([])
        else:
            ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y'))
        for lt in ax.get_xticklabels():
            lt.set_ha('center')
        ax.set_xlabel('')


class Plot:
    """
    Represents a plot configuration.
    """

    def __str__(self):
        return f'    Plot(var={self.var}, file_pattern={self.file_pattern}, sf={self.sf}, title={self.title}, loc={self.row}|{self.col})'

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

    def plot(self, ax):
        """
        Plots the observation data on the given axis.

        Args:
            ax (matplotlib.axes.Axes): Axis to plot on.
        """
        ax.axhline(self.mean, color="k", linestyle="--", label=f'OBS: {self.ref}')
        ax.fill_betweenx([self.mean - self.std, self.mean + self.std], 0, 1, color="k", alpha=0.2)
        ax.set_xlim(0, 1)
        ax.set_xticks([])
        ax.set_yticks([])


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
        self.figs = data.get("figs", {})
        self.legend = data.get("legend", {"NCOL": 3, "AXES": [0.04, 0.01, 0.92, 0.06]})
        self.ts = data.get("ts", {})
        self.map = data.get("map", {})
        self.layout = data.get("layout", {
            "SUBPLOT": [1, 1],
            "SIZE": [10, 8],
            "ADJUST": [0.1, 0.9, 0.1, 0.9, 0.4, 0.4],
            "DPI": 150
        })


    def plot_timeseries(self, ax, plot, runs, obs):
        """
        Plots time series data for the given plot configuration.

        Args:
            ax (matplotlib.axes.Axes): Axis to plot on.
            plot (Plot): Plot configuration object.
            runs (list): List of Run objects containing time series data.
            obs (Obs): Observation data for the plot.

        Returns:
            tuple: Handles and labels for the legend.
        """
        print(f'Plot {plot.title}')
        for run in runs:
            run.plot_ts(ax, plot)
        hl, lb = ax.get_legend_handles_labels()
        ax.set_title(plot.title, fontsize=24)
        ax.grid(True)

        # Plot observations if available
        if obs is not None:
            obs.plot(ax)

        return hl, lb


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
def main(runids, plots_cfg="plots.yml", figs_cfg="figs.yml", style_cfg="styles.yml", obss_cfg="obs.yml", cdir=".", out="valso.png"):
    """
    Main function to generate plots with additional axes for observations.

    Args:
        runids (list): List of run IDs to process.
        plots_cfg (str): Path to the plot configuration file.
        figs_cfg (str): Path to the figs.yml file.
        style_cfg (str): Path to the style configuration file.
        obss_cfg (str): Path to the observation configuration file.
        cdir (str): Base directory for data files.
        out (str): Output file name for the generated plot.
    """
    # Load data and styles
    figure = load_figure(figs_cfg)
    plots = load_plots(plots_cfg, figure)
    obss = load_obss(obss_cfg, figure)
    runs = load_runs(style_cfg, runids, cdir)

    for run in runs:
        print(run)
        run.load_ts(plots)

    # Create subplots
    nrows = figure.layout["SUBPLOT"][0]
    ncols = figure.layout["SUBPLOT"][1]
    figsize = np.array([figure.layout["SIZE"][0] * ncols, figure.layout["SIZE"][1] * nrows]) / 25.4  # width, height
    fig, axs = plt.subplots(nrows, ncols, figsize=figsize, squeeze=False)

    for ax in axs.flat:
        ax.set_visible(False)

    # Plot each subplot
    for plot in plots:
        ax = axs[plot.row - 1][plot.col - 1]
        ax.set_visible(True)

        obs = obss.get(plot.name, None)

        # Plot time series in the main axis
        hl, lb = figure.plot_timeseries(ax, plot, runs, obs)

        # Add an additional axis for observations to the right
        x0, y0, width, height = ax.get_position().bounds
        obs_ax = fig.add_axes([x0 + width + 0.02, y0, 0.05, height])  # Adjust the position and width
        obs_ax.set_visible(True)

        # Use the Obs class's plot method
        if obs is not None:
            obs.plot(obs_ax)

    # Finalize and save
    figure.plot_map(axs)

    plt.subplots_adjust(left=figure.layout["ADJUST"][0],
                        right=figure.layout["ADJUST"][1],
                        bottom=figure.layout["ADJUST"][2],
                        top=figure.layout["ADJUST"][3],
                        wspace=figure.layout["ADJUST"][4],
                        hspace=figure.layout["ADJUST"][5])

    figure.add_legend(fig, hl, lb, lvis=True)

    plt.savefig(out, dpi=figure.layout["DPI"], bbox_inches='tight')

    print(f"✅ Saved {out}")

    plt.show()


# ===================== ENTRY POINT =====================
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Generate plots for validation and observation data.")
    parser.add_argument("-runid", nargs="+", required=True, help="List of run IDs to process.")
    parser.add_argument("-plots", default="plots.yml", help="Path to the full plots database.")
    parser.add_argument("-figs", default="figs.yml", help="Path to the selection figs.yml.")
    parser.add_argument("-style", default="styles.yml", help="Path to the style configuration file.")
    parser.add_argument("-dir", default=".", help="Base directory for data files.")
    parser.add_argument("-out", default="valso.png", help="Output file name for the generated plot.")
    args = parser.parse_args()
    main(args.runid, plots_cfg=args.plots, figs_cfg=args.figs, style_cfg=args.style, obss_cfg="obs.yml", cdir=args.dir, out=args.out)
