#!/usr/bin/env python

import argparse

import requests


def _parse_args():
    """Process the command line arguments"""
    parser = argparse.ArgumentParser()

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '-lig_id',
        nargs=1,
        type=str,
        help='Ligand id to get similar targets for'
    )
    group.add_argument(
        '-smiles',
        nargs=1,
        type=str,
        help='Path to SMILES-formatted file'
    )

    parser.add_argument(
        '-results',
        required=False,
        nargs='?',
        type=int,
        default=10,
        help='Number of max templates to list. Defaults to 10'
    )

    args = parser.parse_args()

    # Specifying args with nargs = 1 so it makes a list. Return the
    # ligand_id/SMILES without the list
    if args.lig_id is not None:
        args.lig_id = args.lig_id[0]
    else:
        args.smiles = args.smiles[0]

    return args


def read_smiles(path_to_smiles_file):
    """
    Read the file and return the SMILES and identifier as str

    The assumption is that the file contains only a single SMILES
    string with the second column listing the ligand ID
    """
    with open(path_to_smiles_file) as in_file:
        for line in in_file:
            line = line.rstrip()
            smiles, lig_id = line.split()
            break  # Assume this is a one-line file

    return smiles, lig_id


def request_smiles(lig_id):
    """Fetch the SMILES string for a given ligand ID"""
    r = requests.get(
        "https://data.rcsb.org/rest/v1/core/chemcomp/{}".format(lig_id)
    )
    if r.status_code == requests.codes.ok:
        return r.json()['rcsb_chem_comp_descriptor']['smiles']
    else:
        print(r.text)
        return r.status_code


def request_identifiers(smiles, results):
    """Constructs the request for the RCSB API based on ligand ID"""
    payload = {
        "query": {
            "label": "chemical",
            "node_id": 0,
            "parameters": {
                "type": "descriptor",
                "descriptor_type": "SMILES",
                "value": smiles,
                "match_type": "fingerprint-similarity"
            },
            "type": "terminal",
            "service": "chemical"
        },
        "return_type": "non_polymer_entity",
        "request_options": {
            "pager": {
                "start": 0,
                "rows": results
            },
            "scoring_strategy": "combined",
            "sort": [
                {
                    "sort_by": "score",
                    "direction": "desc"
                }
            ]
        }
    }

    r = requests.post(
        "https://www.rcsb.org/search/data",
        json=payload
    )

    if r.status_code == requests.codes.ok:
        return r.json()
    else:
        print(r.text)
        return r.status_code


def request_targets(identifiers):
    """Constructs the request for the RCSB API based on PDB IDs"""
    payload = {
        "attibutes": None,
        "report": "search_summary",
        "returnType": "non_polymer_entity",
        "identifiers": identifiers
    }

    r = requests.post(
        "https://www.rcsb.org/search/gql",
        json=payload
    )

    if r.status_code == requests.codes.ok:
        return r.json()
    else:
        print(r.text)
        return r.status_code


def main():
    """Run all the things"""
    args = _parse_args()

    if args.lig_id is not None:
        lig_id = args.lig_id
        smiles = request_smiles(args.lig_id)
    else:
        smiles, lig_id = read_smiles(args.smiles)

    if type(smiles) is not str:
        print("\nSomething went wrong")
        exit(1)

    matches = request_identifiers(
        smiles,
        args.results
    )

    # Handle no resuls here but it should be done in the function instead
    if 'statusCode' in matches and matches['statusCode'] == 204:
        exit(0)

    identifiers = list(_['identifier'] for _ in matches['result_set'])

    matches = request_targets(identifiers)

    targets = (
        _['data']['entryId'] for _ in matches
        if _['data']['entity']['chem_comp_id'] != lig_id
    )

    for target in targets:
        print(target)


if __name__ == "__main__":
    main()
