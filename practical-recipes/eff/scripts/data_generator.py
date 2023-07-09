import csv
from faker import Faker
import random
from typing import List
import argparse

def record_generator(category: str):
    r = random.Random()
    fake = Faker(use_weighting=False)
    id_ctr = 0
    id_prefix = category
    while True:
        yield [
            f"{id_prefix}_{id_ctr}",  # id
            category,  # category
            fake.company(),  # name
            round(r.uniform(100, 1000), 2),  # price
            str(fake.boolean()).lower(),  # inStock
            fake.sentence(), # sentence
            fake.name(),  # author
            fake.job(),  # series_txt
            r.randint(0, 10),  # sequence_i
            fake.color_name()  # genre_s
        ]
        id_ctr += 1


def generate_records_file(filename: str, num_records: int = 10):
    fields = ["id", "category", "name", "price", "inStock", "description", "author", "series_txt", "sequence_i", "genre_s"]
    rgen = record_generator("book")
    ext_data = []

    with open(filename, "w") as csvfile:
        csvwriter = csv.writer(csvfile)

        csvwriter.writerow(fields)
        for _ in range(num_records):
            record = next(rgen)
            ext_data.append([record[0], record[3]])
            csvwriter.writerow(record)
    return ext_data


def generate_eff_file(filename: str, data: List):
    with open(filename, "w") as csvfile:
        csvwriter = csv.writer(csvfile, delimiter="=")
        for record in data:
            csvwriter.writerow(record)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Solr Eff Data Generator",
        description="Generates indexing data for eff_recipe solr collection")
    parser.add_argument("-r", "--records_file", dest="records_file", type=str, help="csv file path to which records should be written")
    parser.add_argument("-n", "--num_records", dest="num_records", type=int, help="num of csv records to be generated")
    parser.add_argument("-p", "--popularity_file", dest="popularity_file", type=str, help="file path to which id=popularity mapping should be written")
    args = parser.parse_args()

    data = generate_records_file(args.records_file, args.num_records)
    generate_eff_file(args.popularity_file, data)
