#!/usr/bin/env bash

# Download the data
categories=(
All_Beauty
Toys_and_Games
Cell_Phones_and_Accessories
Industrial_and_Scientific
Gift_Cards
Musical_Instruments
Electronics
Handmade_Products
Arts_Crafts_and_Sewing
Baby_Products
Health_and_Household
Office_Products
Digital_Music
Grocery_and_Gourmet_Food
Sports_and_Outdoors
Home_and_Kitchen
Subscription_Boxes
Tools_and_Home_Improvement
Pet_Supplies
Video_Games
Kindle_Store
Clothing_Shoes_and_Jewelry
Patio_Lawn_and_Garden
Unknown
Books
Automotive
CDs_and_Vinyl
Beauty_and_Personal_Care
Amazon_Fashion
Magazine_Subscriptions
Software
Health_and_Personal_Care
Appliances
Movies_and_TV
)

for category in ${categories[@]}; do
    wget https://datarepo.eng.ucsd.edu/mcauley_group/data/amazon_2023/benchmark/0core/rating_only/${category}.csv.gz
    gunzip ${category}.csv.gz
    hdfs dfs -put ${category}.csv /user/root/
    rm ${category}.csv
done