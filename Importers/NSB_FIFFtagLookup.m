function str = NSB_FIFFtagLookup(Id,type)
%
%types Units (B.1), unitm (B.2), ch_type (B.3), block
%
%TO Add B.4 - B.22


switch type
    case 'units'
        switch Id
            case -1
                str = 'none';
            case 0
                str = 'NA';
            case 1
                str = 'm';
            case 2
                str = 'kg';
            case 3
                str = 'sec';
            case 4
                str = 'A'; %ampere
            case 5
                str = 'K'; %Kelvin
            case 6
                str = 'mol';
            case 7
                str = 'rad';
            case 8
                str = 'sr'; %steradian
            case 9
                str = 'cd'; %candela
            case 101
                str = 'Hz';
            case 102
                str = 'N'; %Newton
            case 103
                str = 'Pa'; %pascal
            case 104
                str = 'J'; %joule
            case 105
                str = 'W'; %watt
            case 106
                str = 'C'; %coulombe
            case 107
                str = 'V';
            case 108
                str = 'F'; %farad
            case 109
                str = 'Ohm';
            case 110
                str = 'Mho'; %one per ohm
            case 111
                str = 'Wb'; %Webber
            case 112
                str = 'T'; %Tesla
            case 113
                str = 'H'; %Henery
            case 114
                str = 'Cel'; %Celsius
            case 115
                str = 'lm'; %loumen
            case 116
                str = 'lx'; %lux
            case 201
                str = 'T_m'; %T/m
            case 202
                str = 'Am'; %Am
            otherwise
                str = 'NA';
        end
    case 'unitm'
        switch Id
            case 18
                str = 'e';
            case 15
                str = 'pet';
            case 12
                str = 't';
            case 9
                str = 'gig';
            case 6
                str = 'meg';
            case 3
                str = 'k';
            case 2
                str = 'h';
            case 1
                str = 'da';
            case 0
                str = 'none';
            case -1
                str = 'd';
            case -2
                str = 'c';
            case -3
                str = 'm';
            case -6
                str = 'mu';
            case -9
                str = 'n';
            case -12
                str = 'p';
            case -15
                str = 'f';
            case -18
                str = 'a';
            otherwise
                str = 'none';
        end
    case 'ch_type'
        switch Id
            case 1
                str = 'MEG';
            case 2
                str = 'EEG';
            case 3
                str = 'STIM';
            case 102
                str = 'BIO';
            case 201
                str = 'MCG';
            case 202
                str = 'EOG';
            case 301
                str = 'REF_MEG';
            case 302
                str = 'EMG';
            case 402
                str = 'ECG';
            case 502
                str = 'misc';
            case 602
                str = 'Resp';
            case 700
                str = 'quat0';
            case 701
                str = 'quat1';
            case 702
                str = 'quat2';
            case 703
                str = 'quat3';
            case 704
                str = 'quat4';
            case 705
                str = 'quat5';
            case 706
                str = 'quat6';
            case 707
                str = 'HPI_goodness';
            case 708
                str = 'HPI_error';
            case 709
                str = 'HPI_movement';
            case 900
                str = 'syst';
            case 910
                str = 'ias';
            case 920
                str = 'exci';
            case 1000
                str = 'dipole_wave';
            case 1001
                str = 'fit_goodness';
            otherwise
                str = '';
        end
    case 'block'
        switch Id
            case 100
                str = 'meas';
            case 101
                str = 'meas_info';
            case 102
                str = 'raw_data';
            case 103
                str = 'processed_data';
            case 104
                str = 'evoked';
            case 105
                str = 'aspect';
            case 106
                str = 'subject';
            case 107
                str = 'isotrak';
            case 108
                str = 'hpi_meas';
            case 109
                str = 'hpi_result';
            case 110 
                str = 'hpi_coil';
            case 111
                str = 'project';
            case 112
                str = 'continuous_data';
            case 114
                str = 'void';
            case 115
                str = 'events';
            case 116
                str = 'index';
            case 117
                str = 'dacq_pars';
            case 118
                str = 'ref';
            case 119
                str = 'maxshield_raw_data';
            case 120
                str = 'maxshield_aspect';
            case 121
                str = 'hpi_subsystem';
            case 122
                str = 'phantom_subsystem';
            case 200
                str = 'structural_data';
            case 201
                str = 'volume_data';
            case 202
                str = 'volume_slice';
            case 203
                str = 'scenery';
            case 204
                str = 'scene';
            case 205
                str = 'mri_seg';
            case 206
                str = 'mri_seg_region';
            case 300
                str = 'sphere';
            case 310
                str = 'bem';
            case 311
                str = 'bem_surf';
            case 312
                str = 'conductor_model';
            case 313
                str = 'xfit_proj';
            case 314
                str = 'xfit_proj_item';
            case 315
                str = 'xfit_aux';
            case 359
                str = 'bad_channels';
            case 400
                str = 'vol_info';
            case 500
                str = 'data_correction';
            case 501
                str = 'channels_decoupler';
            case 502
                str = 'sss_info';
            case 503
                str = 'sss_cal_adjust';
            case 504
                str = 'sss_st_info';
            case 505
                str = 'sss_bases';
            case 510
                str = 'maxshield';
            case 900
                str = 'processing_history';
            case 901
                str = 'processing_record';
            case 999
                str = 'root';
            otherwise
                str = 'NA';
        end
              
end

                            
                                                                                                        
