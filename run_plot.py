import os
import re
import numpy as np
import glob
import yaml
import xarray as xr
import pandas as pd
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.gridspec import GridSpec
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
        return f'    Run(runid={self.runid}, name={self.name}, line={self.line}, color={self.color}, marker={self.marker}, dir={self.dir})'

    def __init__(self, cdir, runid, name, line="-", color="black", marker="o"):
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
        self.marker = marker
        self.color = color
        self.dir = os.path.join(cdir, self.runid)
        self.ts = {}

    def load_ts(self, plots):
        """
        Loads time series data for the run using a Plot object.
    
        Args:
            plots (list): List of Plot configuration objects.
    
        Returns:
            pd.DataFrame: Time series data.
        """
        for plot in plots:
            file_pattern = plot.file_pattern
            var_pattern = plot.var  # ex: 'toto|titi'
            sf = plot.sf
            files = glob.glob(os.path.join(self.dir, file_pattern))
            print(plot)
            if not files:
                raise FileNotFoundError(f'No files match {file_pattern} in {self.dir}')
    
            # open data
            try:
                ctime = 'time_centered'
                ds = xr.open_mfdataset(files, parallel=True, concat_dim='time_counter', combine='nested').sortby(ctime)
            except:
                ctime = 'time_counter'
                ds = xr.open_mfdataset(files, parallel=True, concat_dim='time_counter', combine='nested').sortby(ctime)
    
            # gestion des variables avec regex
            matched_vars = [v for v in ds.data_vars if re.fullmatch(var_pattern, v)]
            if not matched_vars:
                raise KeyError(f"No variable in dataset matches pattern '{var_pattern}'")
            if len(matched_vars) > 1:
                raise ValueError(f"Multiple variables match pattern '{var_pattern}': {matched_vars}")
    
            var = matched_vars[0]  # on prend la seule variable valide
    
            da = xr.DataArray(ds[var].values.squeeze() * sf, [(ctime, ds[ctime].values)], name=self.name)
    
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

        # plot.var = "sum_iceberg_tmask|sum_berg_melt_tmask"
        pattern = plot.var
        
        # trouver toutes les colonnes de self.ts qui matchent le pattern
        matched_keys = [k for k in self.ts.keys() if re.fullmatch(pattern, k)]
        if not matched_keys:
            raise KeyError(f"No variable matches pattern '{pattern}' in self.ts")
        elif len(matched_keys) > 1:
            print(f"Warning: multiple matches found: {matched_keys}, using all")
        var = matched_keys[0]

        self.ts[var].plot(ax=ax, legend=False, label=self.name, linestyle=self.line, marker=self.marker, color=self.color)

        rmin  = self.ts[var].values.min()
        rmax  = self.ts[var].values.max()

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

    def __init__(self, data, obs):
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
        self.rowspan = data.get("ROWSPAN", 1)
        self.colspan = data.get("COLSPAN", 1)
        self.time = data.get("TIME", False)
        self.fig_file = data.get("FIG_FILE", None)
        self.ymin = obs.obs_min
        self.ymax = obs.obs_max

    def plot_timeseries(self, runs):
        """
        Plots time series data for the given plot configuration.

        Args:
            ax (matplotlib.axes.Axes): Axis to plot on.
            runs (list): List of Run objects containing time series data.

        Returns:
            tuple: Handles and labels for the legend.
        """
        rmin = self.ymin
        rmax = self.ymax
        for run in runs:
            zmin, zmax = run.plot_ts(self.ax, self)
            rmin = min(rmin, zmin)
            rmax = max(rmax, zmax)
        rrange = rmax - rmin
        self.ymin = rmin - 0.02 * rrange
        self.ymax = rmax + 0.02 * rrange

        self.ax.set_ylim([self.ymin, self.ymax])
        hl, lb = self.ax.get_legend_handles_labels()
        self.ax.set_title(self.title, fontsize=24)
        self.ax.grid(True)
        return hl, lb

    def plot_observation(self, obs):
        """
        Plots observation data for the given plot configuration.

        Args:
            ax (matplotlib.axes.Axes): Axis to plot on.
            obs (Obs): Observation data for the plot.
        """

    
        if obs is not None:
            # Add an additional axis for observations to the right
            x0 = self.ax.get_position().x1
            x1 = x0 + 0.02
            y0 = self.ax.get_position().y0
            y1 = self.ax.get_position().y1

            # define axes for observation
            obs_ax = plt.axes([x0+0.005, y0, x1-x0, y1-y0])
            obs_ax.set_visible(True)

            # plot observation
            plt.errorbar(0, obs.mean, yerr=obs.std, fmt='*', markeredgecolor='k', markersize=8, color='k', linewidth=2)
            obs_ax.set_xlim([-1, 1])
            obs_ax.set_ylim([self.ymin, self.ymax])
            obs_ax.set_xticks([])
            obs_ax.set_yticklabels([])
            obs_ax.grid()

    def set_ax(self, fig, gs):
        """
        Sets the axis for the plot using GridSpec.

        Args:
            fig (matplotlib.figure.Figure): The figure to add the subplot to.
            gs (matplotlib.gridspec.GridSpec): The GridSpec object defining the grid layout.
        """
        row = self.row - 1
        col = self.col - 1
        self.ax = fig.add_subplot(gs[row:row + self.rowspan, col:col + self.colspan])
        self.ax.set_visible(True)


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
        self.obs_max=self.mean+self.std
        self.obs_min=self.mean-self.std

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
            f"ts_keys={list(self.ts.keys())}, "
            f"map={self.map})"
        )

    def plot_map(self, fig, gs):
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
        row=self.map["ROW"]-1
        col=self.map["COL"]-1
        rowspan=self.map["ROWSPAN"]
        colspan=self.map["COLSPAN"]
        ax = fig.add_subplot(gs[row:row + rowspan, col:col + colspan])
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
        print(self)
        print('')
        obss = load_obss(obss_cfg, self)
        plots = load_plots(plots_cfg, self, obss)
        runs = load_runs(style_cfg, runids, cdir)

        for run in runs:
            print(run)
            run.load_ts(plots)

        # Create subplots
        nrows = self.layout["SUBPLOT"][0]
        ncols = self.layout["SUBPLOT"][1]
        figsize = np.array([self.layout["SIZE"][0] * ncols, self.layout["SIZE"][1] * nrows]) / 25.4  # width, height
        fig = plt.figure(figsize=figsize)
        gs = GridSpec(nrows, ncols, figure=fig)
        
        # Set axes for each plot
        for plot in plots:
            plot.set_ax(fig, gs)

        # Plot time series
        for plot in plots:
            hl, lb = plot.plot_timeseries(runs)

        # Plot map if specified
        if self.map:
            self.plot_map(fig, gs)

        # Adjust layout
        plt.subplots_adjust(*self.layout["ADJUST"])
        
        # Plot observations
        for plot in plots:
            obs = obss.get(plot.name, None)
            plot.plot_observation(obs)

        # Add legend
        self.add_legend(fig, hl, lb, lvis=True)

        # Finalize and save figure
        plt.savefig(out, dpi=self.layout["DPI"], bbox_inches='tight')
        print(f"✅ Saved {out}")
        print('')

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


def load_plots(plots_file, figure, obss):
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
        selected.append(Plot(data, obss[key]))
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
