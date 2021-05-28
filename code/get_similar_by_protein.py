#!/usr/bin/env python

import argparse

import requests


def _parse_args():
    """Process the command line arguments"""
    parser = argparse.ArgumentParser()

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '-pdb_id',
        nargs=1,
        type=str,
        help='PDB id to get similar targets for'
    )
    group.add_argument(
        '-fasta',
        nargs=1,
        type=str,
        help='Path to FASTA-formatted sequence file'
    )

    parser.add_argument(
        '-chain',
        required=False,
        nargs='?',
        type=str,
        help='Chain to target in the PDB file'
    )
    parser.add_argument(
        '-seqid',
        required=False,
        nargs='?',
        type=float,
        default=0.9,
        help='Sequence identity cutoff. Defaults to 0.9'
    )
    parser.add_argument(
        '-results',
        required=False,
        nargs='?',
        type=int,
        default=10,
        help='Number of max templates to list. Defaults to 10'
    )
    parser.add_argument(
        '-shape',
        required=False,
        choices=['relaxed', 'strict'],
        default=None,
        const='strict',
        nargs='?',
        help='Use 3D shape filtering. If used defaults to strict'
    )

    args = parser.parse_args()

    # Specifying args with nargs = 1 so it makes a list. Return the
    # pdbid/fasta without the list
    if args.pdb_id is not None:
        args.pdb_id = args.pdb_id[0]
    else:
        args.fasta = args.fasta[0]

    return args


def read_sequence(path_to_fasta_file):
    """Read the file and return the sequence as str"""
    sequence = []
    with open(path_to_fasta_file) as in_file:
        for line in in_file:
            if line.startswith('>'):
                continue
            sequence.append(line.rstrip())
    return "".join(sequence)


def request_sequence(pdbid, chain=None):
    """Fetch the sequence for a given PDBID"""
    r = requests.get("https://www.rcsb.org/search/sequence/{}".format(pdbid))
    if r.status_code == requests.codes.ok:
        sequence_response = r.json()
        if len(sequence_response) == 1:
            return sequence_response[0][3:]
        else:
            if chain is not None:
                for chain_seq in sequence_response:
                    chain_id = chain_seq[0]
                    if chain_id == chain:
                        return chain_seq[3:]
            else:
                print("More than one chains detected:\n")
                for chain in sequence_response:
                    print(chain)
                return r.status_code
    else:
        print(r.text)
        return r.status_code


def request_targets(pdbid, sequence, id_cutoff, results, shape):
    """Constructs the request for the RCSB API based on PDBID"""
    payload = {
        "query": {
            "type": "group",
            "logical_operator": "and",
            "nodes": [
                {
                    "type": "terminal",
                    "service": "sequence",
                    "parameters": {
                        "evalue_cutoff": 10,
                        "identity_cutoff": id_cutoff,
                        "target": "pdb_protein_sequence",
                        "value": sequence
                    },
                    "label": "sequence",
                    "node_id": 0
                },
            ]
        },
        "request_options": {
            "pager": {
                "start": 0,
                "rows": results
            },
            "scoring_strategy": "sequence",
        },
        "return_type": "entry"
    }

    if shape is not None:
        payload['query']['nodes'].append(
            {
                "type": "terminal",
                "service": "structure",
                "parameters": {
                    "value": {
                        "entry_id": pdbid,
                        "asym_id": "A",
                    },
                    "operator": "{}_shape_match".format(shape)
                },
                "node_id": 1
            }

        )
        payload['request_options']['scoring_strategy'] = "structure"

    r = requests.post(
        "https://www.rcsb.org/search/data",
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

    if args.pdb_id is not None:
        sequence = request_sequence(args.pdb_id, args.chain)
    else:
        sequence = read_sequence(args.fasta)

    if type(sequence) is not str:
        print("\nSomething went wrong")
        exit(1)

    matches = request_targets(
        args.pdb_id,
        sequence,
        args.seqid,
        args.results,
        args.shape
    )

    targets = (_['identifier'] for _ in matches['result_set'])

    for target in targets:
        print(target)


if __name__ == "__main__":
    main()
