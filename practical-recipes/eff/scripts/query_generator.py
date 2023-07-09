import csv
from faker import Faker
import random
from itertools import cycle
import argparse


def record_generator(filename: str, infiltrate_percent):
    r = random.Random()
    fake = Faker(use_weighting=False)
    genuine_authors = []
    with open(filename, 'r') as csvfile:
        csvreader = csv.reader(csvfile)
        fields = next(csvreader)
        author_idx = fields.index("author")
        for row in csvreader:
            genuine_authors.append(row[author_idx])
    num_genuine_authors = len(genuine_authors)
    num_random_authors = int((infiltrate_percent * num_genuine_authors) / (100 - infiltrate_percent))
    random_authors = []
    for _ in range(num_random_authors):
        random_authors.append(fake.name())
    authors = genuine_authors + random_authors
    r.shuffle(authors)
    print("genuine_authors: ", num_genuine_authors, "\nrandom_authors: ", num_random_authors)
    for author_term in cycle(authors):
        yield [f"fq=author:{author_term}"]

def generate_query_file(filename: str, num_records: int, rgen):
    fields = ["query"]

    with open(filename, 'w') as csvfile:
        csvwriter = csv.writer(csvfile)

        csvwriter.writerow(fields)
        for _ in range(num_records):
            record = next(rgen)
            csvwriter.writerow(record)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Solr Eff Query Generator",
        description="Generates query samples eff_recipe solr collection given the records file")
    parser.add_argument("-q", "--queries_file", dest="queries_file", type=str, help="csv file path to which queries should be written")
    parser.add_argument("-n", "--num_queries", dest="num_queries", type=int, help="num of queries to be generated")
    parser.add_argument("-i", "--infiltrate_percent", dest="infiltrate_percent", type=int, help="percent of queries (as integer)  to be generated from random data")
    parser.add_argument("-r", "--records_file", dest="records_file", type=str, help="csv file path in which records are available")
    args = parser.parse_args()

    rgen = record_generator(args.records_file, args.infiltrate_percent)
    generate_query_file(args.queries_file, args.num_queries, rgen)
