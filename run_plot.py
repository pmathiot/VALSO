import os
import glob
import yaml
import xarray as xr
import pandas as pd
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

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
                ds = xr.open_mfdataset(files, combine="nested", concat_dim="time_counter")
                da = ds[var] * sf
                self.ts[var] = da.to_dataframe(name=self.name)
        return self.ts

    def plot_ts(self, ax, var):
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
        self.ts[var].plot(ax=ax, label=self.name, linestyle=self.line, color=self.color)



class Plot:
    """
    Represents a plot configuration.
    """

    def __str__(self):
        return f'Plot(var={self.var}, file_pattern={self.file_pattern}, sf={self.sf}, title={self.title})'

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
        self.type = data.get("TYPE", "TS").upper()  # TS = time series, FIG = figure
        self.fig_file = data.get("FIG_FILE", None)
        self.obs_file = data.get("OBS", None)

 #   def plot_obs(self, ax):
        """
        Plots observation data on the given axis.

        Args:
            ax (matplotlib.axes.Axes): Axis to plot on.

        Raises:
            FileNotFoundError: If the observation file does not exist.
            KeyError: If required keys are missing in the observation data.
        """
        if not self.obs_file:
            return  # No observation file to plot

        obs_data = load_obs(self.obs_file)
        mean = obs_data["MEAN"]
        std = obs_data["STD"]
        ref = obs_data.get("REF", "OBS")

        # Plot mean and standard deviation as a shaded region
        ax.axhline(mean, color="k", linestyle="--", label=f'OBS: {ref}')
        ax.fill_between(ax.get_xlim(), mean - std, mean + std, color="k", alpha=0.2)

    # need a print option


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
        ax.fill_between(ax.get_xlim(), self.mean - self.std, self.mean + self.std, color="k", alpha=0.2)


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


def load_plots(plots_file, figs_file):
    """
    Loads selected plots from plots.yml database based on figs.yml selection.

    Args:
        plots_file (str): Path to the plots.yml file.
        figs_file (str): Path to the figs.yml file.

    Returns:
        list: List of Plot objects.

    Raises:
        ValueError: If a plot key is not found in plots.yml or figs.yml is invalid.
    """
    all_plots = load_yaml(plots_file).get("plots", {})
    figs = load_yaml(figs_file).get("figs", {})
    figs = dict(sorted(figs.items(), key=lambda item: item[0])) # for easy unit testing
    selected = []

    for key, layout in figs.items():
        if key not in all_plots:
            raise ValueError(f"Plot key {key} not found in plots.yml")
        data = dict(all_plots[key])
        data.update(layout)  # add row/col info
        data["NAME"] = key  # add the plot key as NAME
        selected.append(Plot(data))
    return selected


def load_obss(obss_file, figs_file):
    """
    Loads selected plots from plots.yml database based on figs.yml selection.

    Args:
        obss_file (str): Path to the obs.yml file.
        figs_file (str): Path to the figs.yml file.

    Returns:
        list: Dictionary Obs objects.

    Raises:
        ValueError: If a plot key is not found in plots.yml or figs.yml is invalid.
    """
    all_obss = load_yaml(obss_file).get("plots", {})
    figs = load_yaml(figs_file).get("figs", {})
    figs = dict(sorted(figs.items(), key=lambda item: item[0]))  # for easy unit testing
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


# ===================== PLOT FUNCTIONS =====================
def plot_timeseries(ax, plot, runs, obs):
    """
    Plots time series data for the given plot configuration.

    Args:
        ax (matplotlib.axes.Axes): Axis to plot on.
        plot (Plot): Plot configuration object.
        runs (list): List of Run objects.
        obs (dict): Observation data.
        base_dir (str): Base directory for data files.
    """
    for run in runs:
        run.plot_ts(ax, plot.var)
    ax.set_title(plot.title)
    ax.grid(True)

    # Plot observations if available
    if obs is not None:
        obs.plot(ax)


def plot_map(ax, plot):
    """
    Plots a map image for the given plot configuration.

    Args:
        ax (matplotlib.axes.Axes): Axis to plot on.
        plot (Plot): Plot configuration object.

    Raises:
        FileNotFoundError: If the figure file does not exist.
    """
    img_path = os.path.join(plot.fig_file)
    if not os.path.exists(img_path):
        raise FileNotFoundError(f"Figure file {img_path} not found")
    img = plt.imread(img_path)
    ax.imshow(img)
    ax.axis("off")


def add_legend(fig, ncol=3, lvis=True):
    """
    Adds a single legend at the bottom of the figure.
    """
    handles, labels = [], []
    for ax in fig.axes:
        h, l = ax.get_legend_handles_labels()
        handles += h
        labels += l

    # Axes for legend
    lax = fig.add_axes([0.0, 0.05, 1, 0.1])  # bottom = 0.05
    leg = lax.legend(handles, labels, loc='upper left', ncol=ncol, fontsize=12, frameon=False)
    for item in leg.legendHandles:
        item.set_visible(lvis)
    lax.set_axis_off()
    return lax  # Return the legend axes for reference


def add_text(fig, text_lines, ncol=3, lvis=True):
    """
    Adds text below the legend in the figure.

    Args:
        fig (matplotlib.figure.Figure): Figure object.
        text_lines (list of str): Text lines to display.
    """
    # Axes for text
    tax = fig.add_axes([0.0, 0.0, 1, 0.05])  # very bottom
    tax.set_axis_off()

    # Join text lines and place in center
    text_str = "\n".join(text_lines)
    tax.text(0.5, 0.5, text_str, ha='center', va='center', fontsize=12)


# ===================== MAIN FUNCTION =====================
def main(runids, plots_cfg="plots.yml", figs_cfg="figs.yml", style_cfg="styles.yml", obss_cfg="obs.yml", cdir=".", out="valso.png"):
    """
    Main function to generate plots based on configurations.

    Args:
        runids (list): List of run IDs to process.
        plots_cfg (str): Path to the plot configuration file.
        figs_cfg (str): Path to the figs.yml file.
        style_cfg (str): Path to the style configuration file.
        cdir (str): Base directory for data files.
        out (str): Output file name for the generated plot.
    """
    # load data and styles
    plots = load_plots(plots_cfg, figs_cfg)
    obss = load_obss(obss_cfg)
    runs = load_runs(style_cfg, runids, cdir)
    for run in runs:
        print(run)
        run.load_ts(plots)

    # create subplots
    nrows = max(p.row for p in plots)
    ncols = max(p.col for p in plots)
    fig, axs = plt.subplots(nrows, ncols, figsize=(5*ncols, 4*nrows), squeeze=False)

    # plot each subplot
    for plot in plots:
        ax = axs[plot.row-1][plot.col-1]
        obs = obss.get(plot.name, None)
        if plot.type == "TS":
            plot_timeseries(ax, plot, runs, obs)
        elif plot.type == "FIG":
            plot_map(ax, plot)

    # finalize and save
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    add_legend(fig, ncol=3, lvis=True)
    add_text(fig, ["This is additional info", "Second line of text"])
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
    main(args.runid, plots_cfg=args.plots, figs_cfg=args.figs, style_cfg=args.style, cdir=args.dir, out=args.out)
