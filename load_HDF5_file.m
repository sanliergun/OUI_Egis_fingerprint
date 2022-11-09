function[rf_data_bl, rf_data_fp, txrx_indices, error_flag] = load_HDF5_file(rootpath)

    error_flag = 0;
    rf_data_bl = [];
    rf_data_fp = [];
    txrx_indices =[2, 247, 2, 247];
    
    if exist([rootpath 'last_used_directory.mat'],'file')
        load([rootpath 'last_used_directory.mat'], 'last_used_path');
        i0 = strfind(last_used_path, '/');
        if isempty(i0)
            i0 = strfind(last_used_path, '\');
        end
        last_used_path = last_used_path(1:i0(end)-1);
    else
        last_used_path = rootpath;
    end
    last_used_path = uigetdir(last_used_path,'Select Data Folder.');
    
    if last_used_path == 0
        disp('No directory selected.')
        error_flag = 1;
    else
        bl_filename = dir([last_used_path '/*_baseline.hdf5']);
        bl_filename = bl_filename(1);
        fp_filename = dir([last_used_path '/*_raw.hdf5']);
        fp_filename = fp_filename(1);
        rf_data_bl = h5read([bl_filename.folder '/' bl_filename.name], '/scan');
        rf_data_fp = h5read([fp_filename.folder '/' fp_filename.name], '/scan');
        save([rootpath 'last_used_directory.mat'], 'last_used_path');
    end
