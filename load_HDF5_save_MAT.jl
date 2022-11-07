# load_JLD2_save_MAT.jl

using FileIO
using JLD2
using HDF5
using MAT

dirname = "/Volumes/GoogleDrive/Shared drives/proj-fingerprint-data/scan_data/fingerprints/scans_11_4_2022/scan-11-4-22-v1_2022-11-04.14.50.17/";
filename = "scan_raw.hdf5";
fullname = string(dirname, filename);
# println(fullname)

vars = load(fullname);
rf_data = vars["scan"];

fileoutname = string(dirname, filename[1:end-5], ".mat");

println(fileoutname)
fileout = matopen(fileoutname, "w")
write(fileout, "rf_data", rf_data);
close(fileout);