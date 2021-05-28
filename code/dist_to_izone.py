#!/usr/bin/env python

"""
Format an atom-based contact list in ProFit syntax

Usage:
    python dist_to_izone.py [-res|-atom] <contact_file>

Specifically format an atom-based contact list in izone statements taking into
account any contiguous segments as well as icodes.

For the atom-based transfomation this script respects the output of ligdist
from this package.
"""

__version__ = '0.1.0'
__author__ = 'Panagiotis Koukos'
__email__ = 'p.koukos@uu.nl'

import argparse
from itertools import groupby


def _check_args():
    """Constructs and sanity-checks the command-line arguments"""
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        '-V',
        '--version',
        action='version',
        version='%(prog)s {}'.format(__version__),
        help='Print the version and exit'
    )
    parser.add_argument(
        'input_file',
        help='Path to the input file'
    )

    args = parser.parse_args()
    return(args)


def join_list(residues):
    """
    Join the contiguous segments of a sorted list.

    This is useful for using as few zone definitions as possible
    for PROFIT. The input is a list of resid + icode (optional).
    """
    def keyfunc(s):
        # Stolen from https://stackoverflow.com/a/16956262
        return [
            int(''.join(g)) if k else ''.join(g)
            for k, g in groupby('\0'+s, str.isdigit)
        ]

    sorted_residues = sorted(residues, key=keyfunc)

    joined_list = []
    for index in sorted_residues:
        joined_list.append([
            index,
            index
        ])

        # If one of the indeces contains an icode that will cause the int
        # conversion to fail, therefore for the residues with icodes we
        # are only keeping the single zone statements instead of joining
        # them into the ranged statements.
        try:
            if len(joined_list) > 1:
                if int(joined_list[-2][1]) + 1 == int(joined_list[-1][1]):
                    joined_list[-2][1] = joined_list[-1][1]
                    del joined_list[-1]
        except ValueError:
            continue

    return joined_list


def main():
    """Run the command line script."""
    args = _check_args()

    ifs = open(args.input_file)

    # First pass. Get all the chains.
    chains = set()
    for line in ifs:
        words = line.split()
        chains.add(words[1])
        chains.add(words[4])

    # Second pass. Get all the residues
    residues = {}
    for chain in chains:
        ifs.seek(0)
        residues[chain] = set()
        for line in ifs:
            words = line.split()
            if words[1] == chain:
                residues[chain].add(words[0])
            if words[4] == chain:
                residues[chain].add(words[3])

    ifs.close()

    for chain in residues:
        joined_residue_list = join_list(residues[chain])
        for residue_range in joined_residue_list:
            print(
                "zone {}{}-{}{}".format(
                    chain,
                    residue_range[0],
                    chain,
                    residue_range[1]
                )
            )

if __name__ == "__main__":
    main()
