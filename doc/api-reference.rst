API Reference
=============

BBN provides a C-API shared library (libaps2) for communicating with the APS2,
as well as MATLAB and Julia wrappers for the driver.  We follow language
conventions for index arguments, so channel arguments in the C-API are zero-
indexed, while in MATLAB and Julia they are one-indexed. Most of the C-API
methods require a device serial (an IP address) as the first argument. In
MATLAB and Julia, the serial is stored in a device object and helper functions
inject it as necessary.

Before calling a device specific API the device must be connected by calling
``connect_APS``. This sets up the ethernet interface.  Unloading the shared
library without disconnecting all APS2s may cause a crash as the library
unloading order is uncontrolled. In addition, after every APS2 reset
``init_APS`` must be called once to properly setup the DAC timing and cache-
controller.

Enums
------------------

Nearly all the library calls return an ``APS2_STATUS`` enum.  If there are no
errors then this will be ``APS2_OK``. Otherwise a more detailed description of
the error an be obtained from ``get_error_msg``.  See the Matlab and Julia
drivers for examples of how to wrap each library call with error checking. The
enum and descriptions can be found ``APS2_errno.h``.

There are also enums for the trigger mode, run mode, running status and
logging level.  These can be found in ``APS2_enums.h`` or ``logger.h``.

High-level methods
------------------

Getter calls return the value in the memory referenced by the passed pointer.
The caller is responsible for allocating and managing the memory.

`const char *get_error_msg(APS2_STATUS)`

	Returns the null-terminated error message string associated with the
	``APS2_STATUS`` code.

`APS2_STATUS get_numDevices(unsigned int *numDevices)`

	This method sends out a broadcast packet to find all APS2's on the local
	subnet and returns the number of devices found.

`APS2_STATUS get_device_IPs(const char **deviceIPs)`

	Populates `deviceIPs[]` with C strings of APS2 IP addresses. The caller is
	responsible for sizing deviceIPs appropriately. For example, in C++::

		int numDevices = get_numDevices();
		const char** serialBuffer = new const char*[numDevices];
		get_device_IPs(serialBuffer);

`APS2_STATUS connect_APS(const char *deviceIP)`

	Connects to the APS2 at the given IP address.

`APS2_STATUS disconnect_APS(const char *deviceIP)`

	Disconnects the APS2 at the given IP address.

`APS2_STATUS reset(const char *deviceIP, APS2_RESET_MODE)`

	Resets the APS2 at the given IP address. The `resetMode` parameter can be used
	to do a hard reset from non-volatile flash memory to either the user or backup
	image or can reset the TCP connection should the host computer not cleanly
	close it.

`APS2_STATUS init_APS(const char *deviceIP, int force)`

	This method initializes the APS2 at the given IP address. This involves
	synchronizing and calibrating the DAC clock timing and setting up the
	cache-controller. If `force` = 0, the driver will attempt to determine if
	this procedure has already been run and return immediately. To force the
	driver to run the initialization procedure, call with `force` = 1.

`APS2_STATUS get_firmware_version(const char *deviceIP, uint32_t *version, uint32_t *git_sha1, uint32_t *build_timestamp, char *version_string)`

	Returns computer and humand readable firmware version information. `version`
	returns the version number of the currently loaded firmware. The major version
	number is contained in bits 15-8, while the minor version number is in bits
	7-0. So, a returned value of 513 indicates version 2.1. Bits 28-16 give the
	number of commits since the tag and the top nibble set to d indicates a dirty
	working tree. `git_sha1` is the first 8 hexadecimal digits of the git SHA1 of
	the latest commit. `build_timestamp` is the build timestamp as a hexadecimal
	string YYMMDDhh. The `version_string` will combine the previous values into a
	human readable string similar to what is returned from `git describe`. Pass a
	null pointer for any unused terms.

`APS2_STATUS get_uptime(const char *deviceIP, double *upTime)`

	Returns the APS2 uptime in seconds.

`APS2_STATUS set_sampleRate(const char *deviceIP, unsigned int rate)`

	Sets the output sampling rate of the APS2 to `rate` (in MHz). By default the
	APS2 initializes with a rate of 1200 MHz. The allow values for rate are: 1200,
	600, 300, and 200. **WARNING**: the APS2 firmware has not been tested with
	sampling rates other than the default of 1200. In particular, it is expected
	that DAC synchronization will fail at other update rates.

`APS2_STATUS get_sampleRate(const char *deviceIP, unsigned int *rate)`

	Returns the current APS2 sampling rate in MHz.

`APS2_STATUS set_channel_offset(const char *deviceIP, int channel, float offset)`

	Sets the offset of `channel` to `offset`. Note that the APS2 offsets the
	channels by digitally shifting the waveform values, so non-zero values of
	offset may cause clipping to occur.

`APS2_STATUS get_channel_offset(const char *deviceIP, int channel, float *offset)`

	Returns the current offset value of `channel`.

`APS2_STATUS set_channel_scale(const char *deviceIP, int channel, float scale)`

	Sets the scale parameter for `channel` to `scale`. This method will cause the
	currently loaded waveforms (and all subsequently loaded ones) to be multiplied
	by `scale`. Values greater than 1 may cause clipping.

`APS2_STATUS get_channel_scale(const char *deviceIP, int channel, float *scale)`

	Returns the scale parameter for `channel`.

`APS2_STATUS set_channel_enabled(const char *deviceIP, int channel, int enabled)`

	Enables (`enabled` = 1) or disables (`enabled` = 0) `channel`. **Currently non-functional**

`APS2_STATUS get_channel_enabled(const char *deviceIP, int channel, int *enabled)`

	Returns the enabled state of `channel`.

`APS2_STATUS set_mixer_amplitude_imbalance(const char * deviceIP, float amp)`

	Set the mixer amplitude imbalance tp `amp` and updates the correction matrix.

`APS2_STATUS get_mixer_amplitude_imbalance(const char * deviceIP, float *amp)`

 Gets the mixer amplitude imbalance.

`APS2_STATUS set_mixer_phase_skew(const char * deviceIP, float skew)`

	Sets the mixer phase skew (radians) to `skew` and updates the correction matrix.

`APS2_STATUS get_mixer_phase_skew(const char * deviceIP, float *skew)`

	Gets the mixer phase skew (radians).

`APS2_STATUS set_mixer_correction_matrix(const char * deviceIP, float *matrix)`

	Sets the complete 2x2 mixer correction matrix.  Pass an array of four float to
	fill the matrix in row major order.

`APS2_STATUS get_mixer_correction_matrix(const char * deviceIP, float *matrix)`

	Gets the complete 2x2 mixer correction matrix in row major order.

`APS2_STATUS set_trigger_source(const char *deviceIP, APS2_TRIGGER_SOURCE source)`

	Sets the trigger source to EXTERNAL, INTERNAL, SYSTEM, or SOFTWARE.

`APS2_STATUS get_trigger_source(const char *deviceIP, APS2_TRIGGER_SOURCE *source)`

	Returns the current trigger source.

`APS2_STATUS set_trigger_interval(const char *deviceIP, double interval)`

	Set the internal trigger interval to `interval` (in seconds).  The
	internal trigger has a resolution of 3.333 ns and a minimum interval of
	6.67ns and maximum interval of ``2^32+1 * 3.333 ns = 14.17s``.

`APS2_STATUS get_trigger_interval(const char *deviceIP, double *interval)`

	Returns the current internal trigger interval.

`APS2_STATUS trigger(const char *deviceIP)`

	Sends a software trigger to the APS2.

`APS2_STATUS set_waveform_float(const char *deviceIP, int channel, float *data, int numPts)`

	Uploads `data` to `channel`'s waveform memory. `numPts` indicates the
	length of the `data` array. :math:`\pm 1` indicate full-scale output.

`APS2_STATUS set_waveform_int(const char *deviceIP, int channel, int16_t *data, int numPts)`

	Uploads `data` to `channel`'s waveform memory. `numPts` indicates the length
	of the `data` array. Data should contain 14-bit waveform data placed into the
	lower 14 bits (13-0) of each int16 element. Bits 15-14 in each array element
	will be ignored.

`APS2_STATUS set_markers(const char *deviceIP, int channel, uint8_t *data, int numPts)`

	**FOR FUTURE USE ONLY** Will add marker data in `data` to the currently
	loaded waveform on `channel`.

`APS2_STATUS write_sequence(const char *deviceIP, uint64_t *data, uint32_t numWords)`

	Writes instruction sequence in `data` of length `numWords`.

`APS2_STATUS load_sequence_file(const char *deviceIP, const char* seqFile)`

	Loads the APS2-structured HDF5 file given by the path `seqFile`. Be aware
	the backslash character must be escaped (doubled) in C strings.

`APS2_STATUS set_run_mode(const char *deviceIP, APS2_RUN_MODE mode)`

	Changes the APS2 run mode to sequence (RUN_SEQUENCE, the default),
	triggered  waveform (TRIG_WAVEFORM) or continuous loop waveform
	(CW_WAVEFORM) **IMPORTANT NOTE** The run mode is not a state and the APS2
	does not "remember" its current playback mode.  The waveform modes simply
	load a simple sequence to play a single waveform. In particular, uploading
	new sequence or waveform data will cause the APS2 to return to 'sequence'
	mode. To use 'waveform' mode, call `set_run_mode` only after calling
	`set_waveform_float` or `set_waveform_int`.

`APS2_STATUS set_waveform_frequency(const char *deviceIP, float freq)`

	Sets the modulation frequency for waveform run mode to `freq`.

`APS2_STATUS get_waveform_frequency(const char *deviceIP, float *freq)`

	Gets the modulation frequency for waveform run mode.

`APS2_STATUS run(const char *deviceIP)`

	Enables the pulse sequencer.

`APS2_STATUS stop(const char *deviceIP)`

	Disables the pulse sequencer.

`APS2_STATUS get_runState(const char *deviceIP, APS2_RUN_STATE *state)`

	Returns the running state of the APS2.

`APS2_STATUS get_mac_addr(const char *deviceIP, uint64_t *MAC)`

	Returns the MAC address of the APS2 at the given IP address.

`APS2_STATUS set_ip_addr(const char *deviceIP, const char *ip_addr)`

	Sets the IP address of the APS2 currently at `deviceIP` to `ip_addr`. The
	IP address does not actually update until `reset()` is called, or the
	device is power cycled.  Note that if you change the IP and reset you will
	have to disconnect and re-enumerate for the driver to pick up the new IP
	address.


Low-level methods
-----------------

`int set_log(char* logfile)`

	Directs logging information to `logfile`, which can be either a full file
	path, or one of the special strings "stdout" or "stderr".

`int set_logging_level(TLogLevel level)`

	Sets the logging level to `level` (values between 0-8 logINFO to logDEBUG4). Determines the
	amount of information written to the APS2 log file. The default logging
	level is 2 or logINFO.

`int write_memory(const char *deviceIP, uint32_t addr, uint32_t* data, uint32_t numWords)`

	Write `numWords` of `data` to the APS2 memory starting at `addr`.

`int read_memory(const char *deviceIP, uint32_t addr, uint32_t* data, uint32_t numWords)`

	Read `numWords` into `data` from the APS2 memory starting at `addr`.

`int read_register(const char *deviceIP, uint32_t addr)`

	Returns the value of the APS2 register at `addr`.
