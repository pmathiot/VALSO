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
