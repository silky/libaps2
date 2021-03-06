% MATLAB wrapper for the APS2 driver.

% Original author: Blake Johnson
% Date: August 11, 2014

% Copyright 2014 Raytheon BBN Technologies
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

classdef APS2 < handle
    properties
        ip_addr = ''
    end

    properties (Constant)
        libpath = '../../build';
        samplingRate = 1200000000 % for now only run at 1.2GS/s
    end

    methods
        function obj = APS2()
            APS2.load_library();
        end

        function delete(obj)
            try
               obj.disconnect();
            catch %#ok<CTCH>
            end
        end

        function aps2_call(obj, func, varargin)
            status = calllib('libaps2', func, obj.ip_addr, varargin{:});
            APS2.check_status(status);
        end

        function val = aps2_getter(obj, func, varargin)
            [status, ~, val] = calllib('libaps2', func, obj.ip_addr, varargin{:}, 0);
            APS2.check_status(status);
        end

        function connect(obj, ip_addr)
            if ~isempty(obj.ip_addr)
              warning('Disconnecting from %s before connecting to %s', obj.ip_addr, ip_addr)
              disconnect(obj)
            end
            obj.ip_addr = ip_addr;
            aps2_call(obj, 'connect_APS');
            obj.init();
        end

        function disconnect(obj)
            aps2_call(obj, 'disconnect_APS');
            obj.ip_addr = '';
        end

        function init(obj, force)
            if ~exist('force', 'var')
                force = 0;
            end
            aps2_call(obj, 'init_APS', force)
        end

        function [ver, ver_str, git_sha1, build_timestamp] = get_firmware_version(obj)
            [status, ~, ver, git_sha1, build_timestamp, ver_str] = calllib('libaps2', 'get_firmware_version', obj.ip_addr, 0, 0, 0, blanks(64));
            APS2.check_status(status);
        end

        function val = get_uptime(obj)
            val = aps2_getter(obj, 'get_uptime');
        end

        function val = get_fpga_temperature(obj)
            val = aps2_getter(obj, 'get_fpga_temperature');
        end

        function run(obj)
            aps2_call(obj, 'run');
        end

        function stop(obj)
            aps2_call(obj, 'stop');
        end

        function val = get_runState(obj)
            val = aps2_getter(obj, 'get_runState');
        end

        % trigger methods
        function val = get_trigger_interval(obj)
            val = aps2_getter(obj, 'get_trigger_interval');
        end

        function set_trigger_interval(obj, val)
            aps2_call(obj, 'set_trigger_interval', val);
        end

        function val = get_trigger_source(obj)
            val = aps2_getter(obj, 'get_trigger_source');
        end

        function set_trigger_source(obj, source)
            aps2_call(obj, 'set_trigger_source', source);
        end

        function trigger(obj)
            aps2_call(obj, 'trigger')
        end

        % waveform and instruction data methods
        function load_waveform(obj, ch, wf)
            switch(class(wf))
                case 'int16'
                    aps2_call(obj, 'set_waveform_int', ch-1, wf, length(wf));
                case 'double'
                    aps2_call(obj, 'set_waveform_float', ch-1, wf, length(wf));
                otherwise
                    error('Unhandled waveform data type');
            end
        end

        function load_sequence(obj, filename)
            aps2_call(obj, 'load_sequence_file', filename);
        end

        function val = get_run_mode(obj)
            val = aps2_getter(obj, 'get_run_mode');
        end

        function set_run_mode(obj, runMode)
            aps2_call(obj, 'set_run_mode', runMode);
        end

        function set_waveform_frequency(obj, freq)
            aps2_call(obj, 'set_waveform_frequency', freq);
        end

        function val = get_waveform_frequency(obj)
            val = aps2_getter(obj, 'get_waveform_frequency');
        end

        % channel methods
        function val = get_channel_offset(obj, channel)
            val = aps2_getter(obj, 'get_channel_offset', channel-1);
        end

        function set_channel_offset(obj, channel, offset)
            aps2_call(obj, 'set_channel_offset', channel-1, offset);
        end

        function val = get_channel_scale(obj, channel)
            val = aps2_getter(obj, 'get_channel_scale', channel-1);
        end

        function set_channel_scale(obj, channel, scale)
            aps2_call(obj, 'set_channel_scale', channel-1, scale);
        end

        function val = get_channel_enabled(obj, channel)
            val = aps2_getter(obj, 'get_channel_enabled', channel-1);
        end

        function set_channel_enabled(obj, channel, enabled)
            aps2_call(obj, 'set_channel_enabled', channel-1, enabled);
        end

        function val = get_channel_delay(obj, channel)
            val = aps2_getter(obj, 'get_channel_delay', channel-1);
        end

        function set_channel_delay(obj, channel, delay)
            aps2_call(obj, 'set_channel_delay', channel-1, delay);
        end

        function set_mixer_amplitude_imbalance(obj, amp)
          aps2_call(obj, 'set_mixer_amplitude_imbalance', amp);
        end

        function val = get_mixer_amplitude_imbalance(obj)
            val = aps2_getter(obj, 'get_mixer_amplitude_imbalance');
        end

        function set_mixer_phase_skew(obj, skew)
          aps2_call(obj, 'set_mixer_phase_skew', skew);
        end

        function val = get_mixer_phase_skew(obj)
            val = aps2_getter(obj, 'get_mixer_phase_skew');
        end

        function set_mixer_correction_matrix(obj, matrix)
            aps2_call(obj, 'set_mixer_correction_matrix', matrix')
        end

        function matrix = get_mixer_correction_matrix(obj)
            matrixPtr = libpointer('singlePtr', zeros(2,2));
            [status, ~, ~] = calllib('libaps2', 'get_mixer_correction_matrix', obj.ip_addr, matrixPtr);
            APS2.check_status(status);
            matrix = matrixPtr.value';
        end

        function setAll(obj,settings)
            %setAll - Sets up the APS2 with a settings structure
            % APS2.setAll(settings)
            % The settings structure can contain
            %  settings.
            %           chan_x.amplitude
            %           chan_x.offset
            %           chan_x.enabled
            %  settings.seqFile - hdf5 sequence file
            %  settings.seqForce - force reload of file

            % Setup some defaults
            if ~isfield(settings, 'seqForce')
                settings.seqForce = 0;
            end
            if ~isfield(settings, 'lastseqFile')
                settings.lastseqFile = '';
            end

            obj.stop();

            % Set the channel parameters;  set amplitude and offset before loading waveform data so that we
 			% only have to load it once.
            channelStrs = {'chan_1','chan_2'};
            if all(isfield(settings, channelStrs))
                for ct = 1:2
                    ch = channelStrs{ct};
    				obj.set_channel_scale(ct, settings.(ch).amplitude);
    				obj.set_channel_offset(ct, settings.(ch).offset);
                    obj.set_channel_enabled(ct, settings.(ch).enabled);
                end
            end

			% load a sequence file if the settings file is changed or if force == true
			if isfield(settings, 'seqFile') && (~strcmp(settings.lastseqFile, settings.seqFile) || settings.seqForce)
                obj.load_sequence(settings.seqFile);
			end

            if isfield(settings, 'triggerInterval')
                obj.set_trigger_interval(settings.triggerInterval);
            end
            if isfield(settings, 'triggerSource')
                obj.set_trigger_source(settings.triggerSource');
            end
        end

        % debug methods

        function out = read_register(obj, addr)
            out = aps2_getter(obj, 'read_register', addr);
        end
    end

    methods (Static)
        function load_library()
            if ~libisloaded('libaps2')
                curPath = fileparts(mfilename('fullpath'));
                loadlibrary('libaps2', fullfile(curPath, 'libaps2.matlab.h'));
            end
        end

        function check_status(status)
            APS2.load_library();
            assert(strcmp(status, 'APS2_OK'),...
            'APS2 library call failed with message: %s', calllib('libaps2', 'get_error_msg', status));
        end

        function ip_addrs = enumerate()
            APS2.load_library();
            [status, numDevices] = calllib('libaps2', 'get_numDevices', 0);
            APS2.check_status(status);
            ip_addrs = cell(1,numDevices);
            for ct = 1:numDevices
                ip_addrs{ct} = '';
            end
            ip_addrPtr = libpointer('stringPtrPtr', ip_addrs);
            [status, ip_addrs] = calllib('libaps2', 'get_device_IPs', ip_addrPtr);
            APS2.check_status(status)
        end

        function set_logging_level(level)
            APS2.load_library();
            status = calllib('libaps2', 'set_logging_level', level);
            APS2.check_status(status);
        end



    end

end
