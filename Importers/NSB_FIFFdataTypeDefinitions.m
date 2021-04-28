function FIFFdef = NSB_FIFFdataTypeDefinitions()
%
%http://www1.aston.ac.uk/lhs/research/centres-facilities/brain-centre/facilities-clinical-services/meg-studies/downloads/
%

%Appendix A
%A.1 Byte ordering
%    FIFF was originally designed for the ?big-endian? (Sun, HP) byte ordering in integers. It was also assumed that the floating point numbers are pre- sented using the IEEE standard. The data in files are always stored in this ordering and floating-point representation irrespective of the computer platform.
%A.2 Data type identifiers
FIFFdef.void = 0;
FIFFdef.byte = 1;
FIFFdef.int16 = 2;
FIFFdef.int32 = 3;
FIFFdef.float = 4;
FIFFdef.double = 5;
FIFFdef.julian = 6;
FIFFdef.uint16 = 7;
FIFFdef.uint32 = 8;
FIFFdef.uint64 = 9;
FIFFdef.char = 10; %also known as string or ascii
FIFFdef.int64 = 11;
FIFFdef.dau_pac13 = 13;
FIFFdef.dau_pac14 = 14;
FIFFdef.dau_pac16 = 16;
FIFFdef.cfloat = 20;
FIFFdef.cdouble = 21;
FIFFdef.old_pack = 23;
FIFFdef.ch_info_struct = 30;
FIFFdef.id_struct = 31;
FIFFdef.dir_entry_struct = 32;
FIFFdef.dig_point_struct = 33;
FIFFdef.ch_pos_struct = 34;
FIFFdef.coord_trans_struct = 35;
FIFFdef.dig_string_struct = 36;
FIFFdef.stream_segment_struct = 37;

%A.3 Basic data types
%Data types match with the basic data types of C language, so that they can be easily expressed in C or C++. Note, however, the definitions of these data types are synonymous to the data types actually found in a FIFF file only in big-endian byte ordering systems using the IEEE floating point representation. Other plat- forms must use proper conversion routines when writing or reading data from a file.
%Data type  Size bytes  Description
%void_t     0           No data
%...

%A.5.2 Matrix representation

%. presently defined tags
%C.1 Acquisition control
FIFFdef.tag.new_file = 1;
FIFFdef.tag.close_file = 2;
FIFFdef.tag.discard_file = 3;
FIFFdef.tag.error_message = 4;
FIFFdef.tag.suspend_reading = 5;
FIFFdef.tag.fatal_error_message = 6;
FIFFdef.tag.connection_check = 7;
FIFFdef.tag.suspend_filing = 8;
FIFFdef.tag.resume_filing = 9;
FIFFdef.tag.raw_prebase = 10; %card
FIFFdef.tag.raw_pick_list = 11;
FIFFdef.tag.echo = 12;
FIFFdef.tag.resume_reading = 13;
FIFFdef.tag.dacq_system_type = 14;
FIFFdef.tag.select_raw_ch = 15;
FIFFdef.tag.playback_mode = 16;
FIFFdef.tag.playback_mode = 17;
FIFFdef.tag.jitter_max = 18;
FIFFdef.tag.stream_segment = 19;

FIFFdef.tag.file_id = 100;
FIFFdef.tag.dir_pointer = 101;
FIFFdef.tag.dir = 102;
FIFFdef.tag.block_id = 103;
FIFFdef.tag.block_start = 104; %enum
FIFFdef.tag.block_end = 105; %enum
FIFFdef.tag.free_list = 106; %ord
FIFFdef.tag.free_block = 107;
FIFFdef.tag.nop = 108;
FIFFdef.tag.parent_file_id = 109;
FIFFdef.tag.parent_block_id = 110;
FIFFdef.tag.block_name = 111;
FIFFdef.tag.block_version = 112;
FIFFdef.tag.creator = 113;
FIFFdef.tag.modifier = 114;
FIFFdef.tag.ref_role = 115;
FIFFdef.tag.ref_file_id = 116;
FIFFdef.tag.ref_file_num = 117;
FIFFdef.tag.ref_file_name = 118;
FIFFdef.tag.ref_block_id = 120;

FIFFdef.tag.dacq_pars = 150;
FIFFdef.tag.dacq_stim = 151;

FIFFdef.tag.nchan = 200;
FIFFdef.tag.sfreq = 201;
FIFFdef.tag.data_pack = 202;
FIFFdef.tag.ch_info = 203;
FIFFdef.tag.meas_date = 204;
FIFFdef.tag.subject = 205;
FIFFdef.tag.description = 206;
FIFFdef.tag.nave = 207;
FIFFdef.tag.first_sample = 208;
FIFFdef.tag.last_sample = 209;
FIFFdef.tag.aspect_kind = 210;
FIFFdef.tag.ref_event = 211;
FIFFdef.tag.experimenter = 212;
FIFFdef.tag.dig_point = 213;
FIFFdef.tag.ch_pos_vec = 214;
FIFFdef.tag.hpi_slopes = 215;
FIFFdef.tag.hpi_ncoil = 216;
FIFFdef.tag.req_event = 217;
FIFFdef.tag.req_limit = 218;
FIFFdef.tag.lowpass = 219;
FIFFdef.tag.bad_chs = 220;
FIFFdef.tag.artef_removal = 221;
FIFFdef.tag.coord_trans = 222;
FIFFdef.tag.highpass = 223;
FIFFdef.tag.ch_cals_vec = 224;
FIFFdef.tag.hpi_bad_chs = 225;
FIFFdef.tag.hpi_corr_coeff = 226;
FIFFdef.tag.event_comment = 227;
FIFFdef.tag.no_samples = 228;
FIFFdef.tag.first_time = 229;
FIFFdef.tag.subave_size = 230;
FIFFdef.tag.subave_first = 231;
FIFFdef.tag.name = 233;
FIFFdef.tag.dig_string = 234;
FIFFdef.tag.line_freq = 235;
FIFFdef.tag.hpi_coil_freq = 236;
FIFFdef.tag.signal_channel = 237;
FIFFdef.tag.hpi_coil_moments = 240;
FIFFdef.tag.hpi_fit_goodness = 241;
FIFFdef.tag.hpi_fit_accept = 242;
FIFFdef.tag.hpi_fit_good_limit = 243;
FIFFdef.tag.hpi_fit_dist_limit = 244;
FIFFdef.tag.hpi_coil_no = 245;
FIFFdef.tag.hpi_coils_used = 246;
FIFFdef.tag.hpi_digitization_order = 247;

FIFFdef.tag.ch_scan_no = 250;
FIFFdef.tag.ch_logical_no = 251;
FIFFdef.tag.ch_kind = 252;
FIFFdef.tag.ch_range = 253;
FIFFdef.tag.ch_cal = 254;
FIFFdef.tag.ch_pos = 255;
FIFFdef.tag.ch_unit = 256;
FIFFdef.tag.ch_unit_mul = 257;
FIFFdef.tag.ch_dacq_name = 258;

%These sections are to be added later
%C.6 Signal space separation (SSS)
%C.7 Gantry information
%C.8 Signal data bits
FIFFdef.tag.data_buffer = 300;
FIFFdef.tag.data_skip = 301;
FIFFdef.tag.epoch = 302;
FIFFdef.tag.data_skip_samp = 303;
FIFFdef.tag.data_buffer2 = 304;
FIFFdef.tag.time_stamp = 305;

%C.9 Patient information
FIFFdef.tag.subj_id = 400;
FIFFdef.tag.subj_first_name = 401;
FIFFdef.tag.subj_middle_name = 402;
FIFFdef.tag.subj_last_name = 403;
FIFFdef.tag.subj_birth_day = 404;
FIFFdef.tag.subj_sex = 405;
FIFFdef.tag.subj_hand = 406;
FIFFdef.tag.subj_weight = 407;
FIFFdef.tag.subj_height = 408;
FIFFdef.tag.subj_comment = 409;
FIFFdef.tag.subj_his_id = 410;

FIFFdef.tag.proj_id = 500;
FIFFdef.tag.proj_name = 501;
FIFFdef.tag.proj_aim = 502;
FIFFdef.tag.proj_persons = 503;
FIFFdef.tag.proj_comment = 504;

FIFFdef.tag.event_channels = 600;
FIFFdef.tag.event_list = 601;
FIFFdef.tag.event_channel = 602;
FIFFdef.tag.event_bits = 603;

%These sections are to be added later
% C.12 SQUID characteristics
% C.13 Volumetric image data
% C.14 Conductor models
% C.15 Source modelling software
% C.16 Signal space projections (SSP)
% C.17 XPlotter
% 
% There is also a Block type section
% D.1 Block types

FIFFdef.block.meas = 100;
FIFFdef.block.meas_info = 101;
FIFFdef.block.raw_data = 102;
FIFFdef.block.processed_data = 103;
FIFFdef.block.evoked = 104;
FIFFdef.block.aspect = 105;
FIFFdef.block.subject = 106;
FIFFdef.block.isotrak = 107;
FIFFdef.block.hpi_meas = 108;
FIFFdef.block.hpi_result = 109;
FIFFdef.block.hpi_coil = 110;
FIFFdef.block.project = 111;
FIFFdef.block.continuous_data = 112;
FIFFdef.block.void = 114;
FIFFdef.block.events = 115;
FIFFdef.block.index = 116;
FIFFdef.block.dacq_pars = 117;
FIFFdef.block.ref = 118;
FIFFdef.block.maxshield_raw_data = 119;
FIFFdef.block.maxshield_aspect = 120;
FIFFdef.block.hpi_subsystem = 121;
FIFFdef.block.phantom_subsystem = 122;
FIFFdef.block.structural_data = 200;
FIFFdef.block.volume_data = 201;
FIFFdef.block.volume_slice = 202;
FIFFdef.block.scenery = 203;
FIFFdef.block.scene = 204;
FIFFdef.block.mri_seg = 205;
FIFFdef.block.mri_seg_region = 206;
FIFFdef.block.sphere = 300;
FIFFdef.block.bem = 310;
FIFFdef.block.bem_surf = 311;
FIFFdef.block.conductor_model = 312;
FIFFdef.block.xfit_proj = 313;
FIFFdef.block.xfit_proj_item = 314;
FIFFdef.block.xfit_aux = 315;
FIFFdef.block.bad_channels = 359;
FIFFdef.block.vol_info = 400;
FIFFdef.block.data_correction = 500;
FIFFdef.block.channels_decoupler = 501;
FIFFdef.block.sss_info = 502;
FIFFdef.block.sss_cal_adjust = 503;
FIFFdef.block.sss_st_info = 504;
FIFFdef.block.sss_bases = 505;
FIFFdef.block.maxshield = 510;
FIFFdef.block.processing_history = 900;
FIFFdef.block.processing_record = 901;
FIFFdef.block.root = 999;
