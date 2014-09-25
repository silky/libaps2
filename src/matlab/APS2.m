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
        serial
        libpath = '../../build';
    end
    
    properties (Constant)
        % run mode enum
        RUN_SEQUENCE = 0
        TRIG_WAVEFORM = 1
        CW_WAVEFORM = 2
    end
    
    methods
        function obj = APS2()
            if ~libisloaded('libaps2')
                curPath = fileparts(mfilename('fullpath'));
                loadlibrary(fullfile(curPath, obj.libpath, 'libaps2.dll'), fullfile(curPath, 'libaps.matlab.h'));
            end
        end
        
        function delete(obj)
            try
               obj.disconnect();
            catch %#ok<CTCH>
            end
        end
        
        function [serials] = enumerate(obj)
            numDevices = calllib('libaps2', 'get_numDevices');
            serials = cell(1,numDevices);
            for ct = 1:numDevices
                serials{ct} = '';
            end
            serialPtr = libpointer('stringPtrPtr', serials);
            serials = calllib('libaps2', 'get_deviceSerials', serialPtr);
        end
        
        function connect(obj, serial)
            obj.serial = serial;
            calllib('libaps2', 'connect_APS', serial);
            obj.init();
        end
        
        function disconnect(obj)
            calllib('libaps2', 'disconnect_APS', obj.serial);
        end
        
        function init(obj, force)
            if ~exist('force', 'var')
                force = 0;
            end
            calllib('libaps2', 'initAPS', obj.serial, force);
        end
        
        function run(obj)
            calllib('libaps2', 'run', obj.serial);
        end
        
        function stop(obj)
            calllib('libaps2', 'stop', obj.serial);
        end
        
        function val = get_running(obj)
            val = calllib('libaps2', 'get_running', obj.serial);
        end
        
        % trigger methods
        function val = get_trigger_interval(obj)
            val = calllib('libaps2', 'get_trigger_interval', obj.serial);
        end
        
        function set_trigger_interval(obj, val)
            calllib('libaps2', 'set_trigger_interval', obj.serial, val);
        end
        
        function val = get_trigger_source(obj)
            triggerSourceMap = containers.Map({0, 1}, {'external', 'internal'});
            val = calllib('libaps2', 'get_trigger_source', obj.serial);
            val = triggerSourceMap(val);
        end
        
        function set_trigger_source(obj, source)
            triggerSourceMap = containers.Map({'external', 'ext', 'internal', 'int'}, {0, 0, 1, 1});
            calllib('libaps2', 'set_trigger_source', obj.serial, triggerSourceMap(lower(source)));
        end
        
        % waveform and instruction data methods
        function load_waveform(obj, ch, wf)
            switch(class(wf))
                case 'int16'
                    calllib('libaps2', 'set_waveform_int', obj.serial, ch-1, wf, length(wf));
                case 'double'
                    calllib('libaps2', 'set_waveform_float', obj.serial, ch-1, wf, length(wf));
                otherwise
                    error('Unhandled waveform data type');
            end
        end
        
        function load_sequence(obj, filename)
            calllib('libaps2', 'load_sequence_file', obj.serial, filename);
        end
        
        function set_run_mode(obj, mode)
            calllib('libaps2', 'set_run_mode', obj.serial, mode);
        end

        % channel methods
        function val = get_channel_offset(obj, channel)
            val = calllib('libaps2', 'get_channel_offset', obj.serial, channel-1);
        end
        
        function set_channel_offset(obj, channel, offset)
            calllib('libaps2', 'set_channel_offset', obj.serial, channel-1, offset);
        end

        function val = get_channel_scale(obj, channel)
            val = calllib('libaps2', 'get_channel_scale', obj.serial, channel-1);
        end
        
        function set_channel_scale(obj, channel, scale)
            calllib('libaps2', 'set_channel_scale', obj.serial, channel-1, scale);
        end

        function val = get_channel_enabled(obj, channel)
            val = calllib('libaps2', 'get_channel_enabled', obj.serial, channel-1);
        end
        
        function set_channel_enabled(obj, channel, enabled)
            calllib('libaps2', 'set_channel_enabled', obj.serial, channel-1, enabled);
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
            
            % If we are going to call load_sequence below, we can clear all channel data first
            if (~strcmp(settings.lastseqFile, settings.seqFile) || settings.seqForce)
				calllib('libaps2', 'clear_channel_data', obj.serial);
            end
            
            obj.stop();
			
            % Set the channel parameters;  set amplitude and offset before loading waveform data so that we
 			% only have to load it once.
            channelStrs = {'chan_1','chan_2'};
            for ct = 1:2
                ch = channelStrs{ct};
				obj.set_channel_scale(ct, settings.(ch).amplitude);
				obj.set_channel_offset(ct, settings.(ch).offset);
                obj.set_channel_enabled(ct, settings.(ch).enabled);
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
        function set_logging_level(obj, level)
            calllib('libaps2', 'set_logging_level', level);
        end
        
        function out = read_register(obj, addr)
            out = calllib('libaps2', 'read_register', obj.serial, addr);
        end
    end
    
end