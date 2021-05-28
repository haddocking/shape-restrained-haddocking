import os 
import glob
import sys

def HIS_dict(HIS_file):
    
    HIS = open(HIS_file, 'r').readlines()
    HIS_dict = {'hise':[], 'hisd':[]}

    for line in HIS :

        if 'HISE' in line :
            resn = line.split(' ')[2]
            HIS_dict['hise'].append(resn)

        if 'HISD' in line :
            resn = line.split(' ')[2]
            HIS_dict['hisd'].append(resn)

    return HIS_dict


def add_HIS_state(cns_file, HIS_file):

    if os.stat(HIS_file).st_size == 0:
        sys.exit('empty {} file'.format(HIS_file))

    output = open('{}.tmp'.format(cns_file), 'w')

    HIS_states = HIS_dict(HIS_file)
    cns = open(cns_file, 'r').readlines()

    for line in cns:
        
        if 'numhise_1' in line:
            numhise = len(HIS_states['hise'])
            output.write('{{===>}} numhise_1={};\n'.format(numhise))

        elif 'numhisd_1' in line:
            numhisd = len(HIS_states['hisd'])
            output.write('{{===>}} numhisd_1={};\n'.format(numhisd))

        elif 'hise_1_' in line:
            hise_n = int(line.split('=')[3].split('_')[-1])
            if hise_n <= len(HIS_states['hise']):
                resn = HIS_states['hise'][hise_n-1]
                output.write('{{===>}} hise_1_{}={};\n'.format(hise_n, resn))
            else:
                output.write(line)

        elif 'hisd_1_' in line:
            hisd_n = int(line.split('=')[3].split('_')[-1])
            if hisd_n <= len(HIS_states['hisd']):
                resn = HIS_states['hisd'][hisd_n-1]
                output.write('{{===>}} hisd_1_{}={};\n'.format(hisd_n, resn))
            else:
                output.write(line)

        else: 
            output.write(line)

    output.close()                
    

if __name__ == "__main__":

    if len(sys.argv) < 3:
        sys.exit('''Usage:

python add_his_protonation run.csn PDB.HIS

the PDB.HIS file is the output file of molprobity with the following format:

HIS ( 1198 )-->HISD
HIS ( 1208 )-->HISD
HIS ( 96 )-->HISE
HIS ( 198 )-->HISE

''')
        
    cns_file = sys.argv[1]
    HIS_file = sys.argv[2]
    
    add_HIS_state(cns_file, HIS_file)
