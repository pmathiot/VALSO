#!/usr/bin/env python3
"""
Unified diagnostic script for NetCDF files using xarray.

This script performs simple diagnostics (mean, sum, min, max, weighted mean)
optionally restricted to geographic subsets (lat/lon box, ij box) and masks.
It autodetects variable names, dimension names, and coordinate names using
regular expressions matching typical NEMO / CMIP / IPSL conventions.
"""

import argparse
import re
import xarray as xr
import numpy as np


# =============================================================================
# Regex patterns
# =============================================================================

# Typical coordinate name patterns
LAT_REGEX = re.compile(r"^(lat|latitude|nav_lat|yt).*", re.IGNORECASE)
LON_REGEX = re.compile(r"^(lon|longitude|nav_lon|xt).*", re.IGNORECASE)

# Dimensions like i, j, x, y, xpos, ypos, ni, nj...
IDIM_REGEX = re.compile(r"^(i|x|ni|xi).*", re.IGNORECASE)
JDIM_REGEX = re.compile(r"^(j|y|nj|yj).*", re.IGNORECASE)


# =============================================================================
# CLI parsing
# =============================================================================

def parse_args():
    """
    Parse command line arguments defining input/output files, diagnostics,
    masking, and subsets (boxes).
    """
    parser = argparse.ArgumentParser(
        description="Compute diagnostics on a NetCDF variable using xarray."
    )

    parser.add_argument("-f", "--file", required=True, help="Input NetCDF file.")
    parser.add_argument("-v", "--var",
                        help="Variable to process. If omitted, all numeric variables are used.")
    parser.add_argument("-m", "--method", required=True,
                        choices=["mean", "sum", "min", "max", "wmean"],
                        help="Diagnostic method to compute.")
    parser.add_argument("--llbox",
                        help="Lat-lon box: 'latmin,latmax,lonmin,lonmax'.")
    parser.add_argument("--ijbox",
                        help="IJ box: 'imin,imax,jmin,jmax'.")
    parser.add_argument("--mask",
                        help="Mask file and variable: 'mask.nc,maskvar'.")
    parser.add_argument("-o", "--output", required=True,
                        help="Output NetCDF file.")

    return parser.parse_args()


# =============================================================================
# Autodetection helpers
# =============================================================================

def detect_coord(ds, regex):
    """
    Detect a coordinate name in a dataset using a regex pattern.

    Parameters
    ----------
    ds : xr.Dataset
    regex : compiled regexp

    Returns
    -------
    str or None
        Matching coordinate name, or None if nothing matches.
    """
    for coord in ds.coords:
        if regex.match(coord):
            return coord
    return None


def detect_dim(ds, regex):
    """
    Detect a dimension name in a dataset using a regex.

    Parameters
    ----------
    ds : xr.Dataset
    regex : compiled regexp

    Returns
    -------
    str or None
        Dimension name, or None if not found.
    """
    for dim in ds.dims:
        if regex.match(dim):
            return dim
    return None


# =============================================================================
# Spatial extraction
# =============================================================================

def apply_llbox(ds, llbox):
    """
    Apply a lat/lon bounding box to a dataset.

    Parameters
    ----------
    ds : xr.Dataset
    llbox : str
        Comma-separated bounds: "latmin,latmax,lonmin,lonmax".

    Returns
    -------
    xr.Dataset
        Subset dataset.
    """
    latmin, latmax, lonmin, lonmax = map(float, llbox.split(","))

    latname = detect_coord(ds, LAT_REGEX)
    lonname = detect_coord(ds, LON_REGEX)

    if latname is None or lonname is None:
        raise ValueError("Could not detect lat/lon coordinate names.")

    return ds.sel({latname: slice(latmin, latmax),
                   lonname: slice(lonmin, lonmax)})


def apply_ijbox(ds, ijbox):
    """
    Apply an index-based bounding box.

    Parameters
    ----------
    ds : xr.Dataset
    ijbox : str
        Comma-separated indices: "imin,imax,jmin,jmax".

    Returns
    -------
    xr.Dataset
        Subset dataset.
    """
    imin, imax, jmin, jmax = map(int, ijbox.split(","))

    idim = detect_dim(ds, IDIM_REGEX)
    jdim = detect_dim(ds, JDIM_REGEX)

    if idim is None or jdim is None:
        raise ValueError("Could not detect i/j dimension names.")

    return ds.isel({idim: slice(imin, imax),
                    jdim: slice(jmin, jmax)})


# =============================================================================
# Mask handling
# =============================================================================

def apply_mask(da, maskfile, maskvar):
    """
    Apply a mask variable to a DataArray.

    Parameters
    ----------
    da : xr.DataArray
    maskfile : str
        Path to mask NetCDF file.
    maskvar : str
        Name of mask variable.

    Returns
    -------
    xr.DataArray
        Masked data array.
    """
    msk = xr.open_dataset(maskfile)[maskvar]
    msk = msk.broadcast_like(da)
    return da.where(msk > 0)


# =============================================================================
# Diagnostic methods
# =============================================================================

def compute_diag(da, method):
    """
    Compute a statistic on a DataArray.

    Parameters
    ----------
    da : xr.DataArray
    method : str
        One of "mean", "sum", "min", "max", "wmean".

    Returns
    -------
    xr.DataArray
        Result of the diagnostic.
    """
    if method == "mean":
        return da.mean()

    elif method == "sum":
        return da.sum()

    elif method == "min":
        return da.min()

    elif method == "max":
        return da.max()

    elif method == "wmean":
        # Try common CF conventions
        for cand in ["areacello", "area", "cell_area", "e1t", "e2t"]:
            if cand in da.coords or cand in da:
                weights = da[cand]
                return da.weighted(weights).mean()
        raise ValueError("Weighted mean requested but no known area weight found.")

    else:
        raise ValueError(f"Unknown method: {method}")


# =============================================================================
# Main program
# =============================================================================

def main():
    """Main routine executing the entire diagnostic workflow."""
    args = parse_args()

    print(f"Opening: {args.file}")
    ds = xr.open_dataset(args.file)

    # Determine which variables to process
    if args.var:
        variables = [args.var]
    else:
        variables = [
            v for v in ds.data_vars
            if np.issubdtype(ds[v].dtype, np.number)
        ]

    print(f"Variables to process: {variables}")

    # Apply boxes
    if args.llbox:
        print(f"Applying lat/lon box: {args.llbox}")
        ds = apply_llbox(ds, args.llbox)

    if args.ijbox:
        print(f"Applying ij box: {args.ijbox}")
        ds = apply_ijbox(ds, args.ijbox)

    results = {}

    for var in variables:
        da = ds[var]

        # Mask
        if args.mask:
            maskfile, maskvar = args.mask.split(",")
            print(f"Applying mask: {maskfile} (var={maskvar})")
            da = apply_mask(da, maskfile, maskvar)

        print(f"Computing {args.method} for {var}")
        results[var] = compute_diag(da, args.method)

    # New name for output variable: <var>_<method>
    outname = f"{var}_{args.method}"
    result_da.name = outname
    
    # Save output
    print(f"Writing output: {args.output}")
    xr.Dataset(results).to_netcdf(args.output)

    print("Done.")


if __name__ == "__main__":
    main()
