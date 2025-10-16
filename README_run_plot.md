# VALSO Plotting Script

This Python script generates **validation plots** from model outputs (e.g. NEMO, Elmer/Ice) and compares them with observations.  
It is fully configurable through YAML files, allowing you to define:
- which variables to plot,
- which simulations to include,
- how to display them (styles, legends, layout),
- and which observations to show.

## What the script does

- Reads NetCDF files for several model runs (using `xarray`).
- Extracts and plots time series variables defined in `plots.yml`.
- Overlays reference observation values (with error bars) defined in `obs.yml`.
- Combines multiple plots into a single figure defined by `figs.yml`.
- Applies consistent line styles and colors defined in `styles.yml`.
- Saves the figure(s) as `.png`.

## Requirements

### Python version
- Python ≥ **3.8**

### Dependencies
Install them using conda:
```bash
conda env create -f YML/valso.yml
```

Activate the environement:
```bash
conda activate valso
```

## Required input files

All inputs are defined through YAML files.
These are usually stored in a `YML/` directory.

| File            | Purpose                                                     | Required  | Default               |
| --------------- | ----------------------------------------------------------- | --------- | --------------------- |
| `plots.yml`     | Defines which variables to read and from which NetCDF files | ✅        | `YML/plots.yml`       |
| `styles.yml`    | Defines how each run should appear (color, line, marker)    | ✅        | `YML/styles.yml`      |
| `obs.yml`       | Defines observation means and uncertainties                 | ✅        | `YML/obs.yml`         |
| `figs.yml`      | Defines the figure layout and which plots to include        | ✅        | `YML/figs.yml`        |

## Command-line usage

### Basic syntax

```bash
python valso_plot.py \
  -runid <RUN1> <RUN2> ... \
  -figs <figs1.yml> [<figs2.yml> ...] \
  -plots <plots.yml> \
  -style <styles.yml> \
  -obs <obs.yml> \
  -dir <base_data_directory (default ./RUNS)> \
  -outs <output1.png> [<output2.png> ...]
```

### Example

```bash
python run_plot.py \
  -runid CTRL EXP1 \
  -figs YML/figs_VALSO.yml \
  -dir /data/VALSO/RUNS \
  -outs VALSO_validation.png
```

This command:

* reads NetCDF files in `/data/VALSO/RUNS/CTRL` and `/data/VALSO/RUNS/EXP1`
* loads configuration from YAMLs
* generates one figure (`VALSO_validation.png`) following the layout in `figs_VALSO.yml`

## Command-line arguments

| Argument | Description                                                | Default          |
| -------- | ---------------------------------------------------------- | ---------------- |
| `-runid` | List of run IDs to plot (must exist in `styles.yml`)       | *Required*       |
| `-figs`  | One or several `figs.yml` files (each produces one figure) | `YML/figs.yml`   |
| `-plots` | Path to `plots.yml` (plot definitions)                     | `YML/plots.yml`  |
| `-style` | Path to `styles.yml` (run colors/lines)                    | `YML/styles.yml` |
| `-obs`   | Path to `obs.yml` (observations)                           | `YML/obs.yml`    |
| `-dir`   | Base directory containing all run subfolders               | `./RUNS/`        |
| `-outs`  | List of output image filenames (must match `-figs` count)  | `output.png`     |

## Example YAML content

### plots.yml

```yaml
plots:
  TGLOBAL:
    VAR: "thetao"
    FILE_PATTERN: "Omon/thetao_*.nc"
    SF: 1.0
    TITLE: "Global mean sea temperature (°C)"
```

### styles.yml

```yaml
runs:
  CTRL:
    NAME: "Control"
    COLOR: "black"
    LINE: "-"
  EXP1:
    NAME: "Experiment 1"
    COLOR: "blue"
    LINE: "--"
```

### obs.yml

```yaml
obs:
  TGLOBAL:
    MEAN: 17.5
    STD: 0.4
    REF: "HadISST (1981–2010)"
```

### figs.yml

```yaml
description:
  NAME: "Global ocean diagnostics"

layout:
  SUBPLOT: [1, 1]
  SIZE: [160, 100]       # mm
  ADJUST: [0.1, 0.9, 0.1, 0.9, 0.3, 0.3]
  DPI: 150

legend:
  NCOL: 2
  AXES: [0.1, 0.02, 0.8, 0.05]

ts:
  TGLOBAL:
    ROW: 1
    COL: 1
```

## Output

The script produces one `.png` file per figure definition (`-outs`).
Each figure includes:

* one or more time series subplots
* optional observation markers (mean ± std)
* consistent axes and legend

![Alt text](FIGURES/example.png?raw=true "Example of the VALSO output")

## Available features

| Feature                       | Description                               |        |
| ----------------------------- | ----------------------------------------- | ------ |
|  Multiple runs                | Plot several simulations together         |        |
|  Automatic variable matching  | Uses regex (`VAR: "thetao                 | sst"`) |
|  Auto-detection of time axis  | Detects `time_centered` or `time_counter` |        |
|  Configurable layout          | Grid layout via `figs.yml`                |        |
|  Observation support          | Mean ± STD displayed as error bars        |        |
|  Shared legend                | Automatically placed according to config  |        |
|  Batch processing             | Handle multiple figures in one call       |        |

## Tips

* Use wildcards in `FILE_PATTERN` to read multi-year datasets:

  ```yaml
  FILE_PATTERN: "Omon/thetao_*.nc"
  ```
* Scaling factors (`SF`) can convert units (e.g. from kg/s to m/y).
* You can disable time axis labels for subplots by setting `TIME: false` in `plots.yml`.
* Use regular expressions in `VAR` to select variables flexibly.

## Example workflow

```bash
# Generate one figure from figs.yml
python run_plot.py -runid CTRL EXP1 -figs YML/figs.yml -outs output.png

# Generate multiple figures at once
python run_plot.py \
  -runid CTRL EXP1 \
  -figs YML/fig1.yml YML/fig2.yml \
  -outs fig1.png fig2.png
```
