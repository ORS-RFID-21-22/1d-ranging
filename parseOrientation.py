# CREATION: 030422 7:41PM

rangeValMapping = { 5:0.1307861328125135,
					10:0.18310058593751322,
					15:0.23541503906251293,
					20:0.28772949218751265,
					25:0.34004394531251236,
					30:0.3923583984375121,
					35:0.4446728515625118,
					40:0.4969873046875115, # 0.47083007812501165
					45:0.5231445312500114,
					50:0.5754589843750111,
					55:0.6277734375000108,
					60:0.6800878906250105,
					65:0.7324023437500102,
					70:0.78471679687501,
					75:0.8370312500000097,
					80:0.8893457031250094,
					85:0.9416601562500091,
					90:0.9939746093750088,
					95:1.0462890625000085 }

angleInd = { -30:0,
			 -25:1,
			 -20:2,
			 -15:3,
			 -10:4,
			  -5:5,
			   0:6,
			   5:7,
			  10:8,
			  15:9,
			  20:10,
			  25:11,
			  30:12 }

import os
import csv

csv_file_name = str(input('CSV File Name: '))
# csv_file_name = '\'' + csv_file_name + '.csv\''

files_noReset = []
files_insufficientSamples = []
num_insufficientSamples = []

directory = os.getcwd() # gets current directory of file

# temporary to store all samples for all ranges
DATA_ARRAY = []

angles = [-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30]

# first index of each array is its range
# second index of each array is total number of samples
for idx, key in enumerate(angles):
	arr = [key]
	DATA_ARRAY.append(arr)
	DATA_ARRAY[idx].append(0) # placeholder for total samples

print_num_times = input('How many prints would you like? ') # debug

################################################
##### START ITERATING THROUGH FILES IN CWD #####
################################################

# iterate through files in current directory
for filename in os.listdir(directory):
	# track whether to parse file or not
	isProblemFile = False # only checking 'no reset'

	# don't parse non-log files
	if filename[-4:] != '.log':
		continue

	f = os.path.join(directory,filename)

	########################################
	##### AT THIS POINT WE HAVE A FILE #####
	########################################

	# check that the object in path is a file (not a directory)
	if os.path.isfile(f):
		file = open(f, "r")
		file_string = file.read()

		# if second char is a 'c' then we're looking at 5cm
		# else get the first 2 digits of the filename as the range
		file_angle = int(filename.split('deg')[0])

		# check if file has multiple log sets
		if (file_string.count('Reset count') == 0):
			files_noReset.append(filename)
			isProblemFile = True
		else:
			# remove leading prints before sampling begins
			# gets the last instance of sampling
			file_string = file_string.split('Reset count')[-1]

		# older versions have a print out of 'reached max count'
		# remove trailing prints after sampling ends
		if ('reached max count' in file_string):
			file_string = file_string.split('reached max count', 1)[0]

		# check if there are less than 1000 samples
		if (file_string.count('num detected') != 1000):
			files_insufficientSamples.append(filename)
			num_insufficientSamples.append(str(file_string.count('num detected')))

		# handle older versions with 1001 'tag range: ' detections
		# remove single extra detection before 'reached max count'
		if (file_string.count('tag range: ') > 1000):
			file_string = file_string.rsplit('tag range: ', 1)[0]


		######################################################
		##### AT THIS POINT WE HAVE A GOOD FILE TO PARSE #####
		######################################################

		# PARSING TO CSV
		if not isProblemFile:
			# add total number of samples from this log to the overall data array
			# placed in second index of the corresponding file range array
			DATA_ARRAY[angleInd.get(file_angle)][1] = DATA_ARRAY[angleInd.get(file_angle)][1] + file_string.count('num detected')

			# look at each line in all samples
			sample_lines = file_string.split('\n')

			for idx in reversed(range(len(sample_lines))): # l = line
				if ('tag range: ' not in sample_lines[idx]):
					# delete lines that don't have 'tag range'
					sample_lines.remove(sample_lines[idx])
				else:
					# get range value on each line and convert to float in DATA_ARRAY
					sample_lines[idx] = sample_lines[idx].split('tag range: ')[-1]
					DATA_ARRAY[angleInd.get(file_angle)].append(float(sample_lines[idx]))

			if print_num_times: # debug
				print(DATA_ARRAY) # debug
				print_num_times = print_num_times - 1 # debug

##################################################
##### AT THIS POINT WE HAVE FINISHED PARSING #####
##################################################

my_csv = open(csv_file_name, 'w') # write mode
csv.writer(my_csv, delimiter=',').writerows(DATA_ARRAY)

# printout scan of files
if len(files_noReset):
	print(str(len(files_noReset)) + ' NUM FILES NO RESET')
	for filename in files_noReset:
		print('    ' + filename)
if len(files_insufficientSamples):
	print(str(len(files_insufficientSamples)) + ' NUM FILES INSUFFICIENT SAMPLES')
	for idx, filename in enumerate(files_insufficientSamples):
		print('    ' + filename + '   >>   contains: ' + num_insufficientSamples[idx])