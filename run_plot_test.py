import pytest
import os
import pandas as pd
import matplotlib.pyplot as plt
from unittest.mock import patch, MagicMock
import xarray as xr
import numpy as np
import yaml

# Import your classes and functions
from run_plot import Run, Plot, load_yaml, load_runs, load_plots, plot_timeseries, plot_map

# ===================== FIXTURES =====================
@pytest.fixture
def fake_yaml(tmp_path):
    # Create a fake plots.yml and figs.yml
    plots_file = tmp_path / "plots.yml"
    figs_file = tmp_path / "figs.yml"
    styles_file = tmp_path / "styles.yml"

    plots_data = {
        "plots": {
            "TEST_TS": {"TITLE": "Test TS", "FILE_PATTERN": "dummy.nc", "VAR": "v", "TYPE": "TS", "SF": 1.0},
            "TEST_FIG": {"TITLE": "Test Fig", "FIG_FILE": "dummy.png", "TYPE": "FIG"}
        }
    }

    figs_data = {
        "figs": {
            "TEST_TS":  {"row": 1, "col": 1},
            "TEST_FIG": {"row": 1, "col": 2}
        }
    }

    styles_data = {
        "runs":   {
            "run1": {"NAME": "RUN 1", "LINE": "-", "COLOR": "blue"},
            "run2": {"NAME": "RUN 2", "LINE": "--", "COLOR": "red"}
        }
    }

    plots_file.write_text(yaml.safe_dump(plots_data))
    figs_file.write_text(yaml.safe_dump(figs_data))
    styles_file.write_text(yaml.safe_dump(styles_data))

    return str(plots_file), str(figs_file), str(styles_file)

# ===================== TESTS =====================
def test_load_yaml(tmp_path):
    file = tmp_path / "test.yml"
    file.write_text("a: 1\nb: 2")
    data = load_yaml(str(file))
    assert data["a"] == 1
    assert data["b"] == 2

def test_load_runs(tmp_path, fake_yaml):
    plots_file, figs_file, styles_file = fake_yaml
    runs = load_runs(styles_file, ["run1", "run2"], tmp_path)
    assert len(runs) == 2
    assert runs[0].name == "RUN 1"
    assert runs[1].line == "--"

def test_load_plots(fake_yaml):
    plots_file, figs_file, styles_file = fake_yaml
    plots = load_plots(plots_file, figs_file)
    assert len(plots) == 2
    assert plots[1].title == "Test TS"
    assert plots[0].type == "FIG"

def test_run_load_ts(tmp_path, fake_yaml):
    # create fake NetCDF
    file = tmp_path / "dummy.nc"
    ds = xr.Dataset({"v": ("time_counter", np.arange(10))}, coords={"time_counter": np.arange(10)})
    ds.to_netcdf(file)

    plots_file, figs_file, styles_file = fake_yaml
    plots = load_plots(plots_file, figs_file)

    run = Run(tmp_path, "r1", "RUN 1")
    ts = run.load_ts(plots[1])
    assert isinstance(ts, pd.DataFrame)
    assert ts["RUN 1"].tolist() == [0,2,4,6,8,10,12,14,16,18]

def test_plot_map(tmp_path):
    # Create dummy image
    img_file = tmp_path / "dummy.png"
    import matplotlib.image as mpimg
    mpimg.imsave(img_file, np.random.rand(5,5,3))

    plot = Plot({"TITLE": "Test Map", "FIG_FILE": str(img_file), "TYPE": "FIG"})
    
    fig, ax = plt.subplots()
    plot_map(ax, plot)
    
    images = [im for im in ax.get_images()]
    assert len(images) == 1
    plt.close(fig)

def test_load_obss(tmp_path):
    # fake obs.yml
    obss_file = tmp_path / "obs.yml"
    obs_data = {
        "obs": {
            "TEST_TS": {"MEAN": 10.0, "STD": 2.0, "REF": "RefObs"}
        }
    }
    obss_file.write_text(yaml.safe_dump(obs_data))

    figs_file = tmp_path / "figs.yml"
    figs_data = {"figs": {"TEST_TS": {"row": 1, "col": 1}}}
    figs_file.write_text(yaml.safe_dump(figs_data))

    fig = load_figure(str(figs_file))
    obss = load_obss(str(obss_file), fig)
    assert "TEST_TS" in obss
    assert isinstance(obss["TEST_TS"], Obs)
    assert obss["TEST_TS"].mean == 10.0
    assert obss["TEST_TS"].std == 2.0

def test_load_figure(tmp_path):
    figs_file = tmp_path / "figs.yml"
    figs_data = {
        "figs": {"TEST_TS": {"row": 1, "col": 1}},
        "legend": {"NCOL": 2, "AXES": [0.1, 0.1, 0.8, 0.1]},
        "layout": {"SUBPLOT": [2,2], "SIZE": [8,6], "ADJUST": [0.1,0.9,0.1,0.9,0.3,0.3], "DPI": 100}
    }
    figs_file.write_text(yaml.safe_dump(figs_data))

    fig = load_figure(str(figs_file))
    assert isinstance(fig, Figure)
    assert fig.legend["NCOL"] == 2
    assert fig.layout["SUBPLOT"] == [2,2]

def test_figure_plot_timeseries(tmp_path):
    # Create dummy dataset
    ncfile = tmp_path / "dummy.nc"
    ds = xr.Dataset({"v": ("time_counter", np.arange(5))}, coords={"time_counter": pd.date_range("2000-01-01", periods=5)})
    ds.to_netcdf(ncfile)

    plot_cfg = {"TITLE": "TS test", "VAR": "v", "FILE_PATTERN": "dummy.nc", "TYPE": "TS", "ROW": 1, "COL": 1}
    plot = Plot(plot_cfg)

    run = Run(str(tmp_path), "r1", "Run1", color="green")
    run.load_ts([plot])

    obs = Obs({"NAME": "TEST_TS", "MEAN": 2.0, "STD": 1.0, "REF": "RefObs"})

    fig = Figure({})
    fig_obj, ax = plt.subplots()
    handles, labels = fig.plot_timeseries(ax, plot, [run], obs)

    assert "Run1" in labels
    assert any("OBS" in l for l in labels) or obs.ref in labels
    plt.close(fig_obj)

def test_figure_add_legend():
    fig, ax = plt.subplots()
    line, = ax.plot([0,1], [0,1], label="Line1")
    fig_class = Figure({})
    lax = fig_class.add_legend(fig, [line], ["Line1"])
    assert lax is not None
    assert not lax.has_data()  # legend axes should be empty
    plt.close(fig)

def test_figure_plot_map(tmp_path):
    img_file = tmp_path / "img.png"
    import matplotlib.image as mpimg
    mpimg.imsave(img_file, np.ones((10,10,3)))

    fig_class = Figure({"map": {"FILE": str(img_file), "POS": [1,1]}})
    fig, axs = plt.subplots(1,1)
    axs = np.array([[axs]])  # match the expected 2D array
    fig_class.plot_map(axs)

    images = axs[0][0].get_images()
    assert len(images) == 1
    plt.close(fig)
