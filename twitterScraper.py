import tweepy
from tweepy import OAuthHandler
from shutil import copyfile
import json
import codecs
import sys
import os
import re

#Script written by Tyler Poole
#Run with Python 2.7: command python twitterScraper.py <ID or Twitter Handle here>
#Accepts either an user's ID or Twitter Handle as the argument
#Twitter Handle can either have the '@' symbol or exclude it, makes no difference
#Program will exit if user does not exist
#Will only gather up to the last known tweet if the user has been scraped before,
#or 3000 of the user's latest tweets if they have not.
#Saves output to a file called "<user's Twitter Handle here>.txt"

consumer_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
consumer_secret = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
access_token = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
access_secret = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

auth = OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_secret)

API = tweepy.API(auth, wait_on_rate_limit=True)

if (sys.argv[1][0] == "@"):
    modeFlag = "username"
    userID = sys.argv[1][1:]
else:
    modeFlag = "id"
    userID = sys.argv[1]

try:
        u = API.get_user(userID)
except Exception:
        print "User not found"
        sys.exit()

if (modeFlag == "id"):
    user = API.get_user(userID)
    userName = user.screen_name
else:
    userName = userID

userHandles = [ userName ]

while userHandles: 
    handle = userHandles.pop()

    try:
        u = API.get_user(handle)
    except Exception:
        pass

    exists = os.path.isfile('./corpora/%s.txt' % handle)
    if exists:
        with open('./corpora/%s.txt' % handle,'r') as f:
            lastKnownTweet =  f.readline().rstrip()
    else:
        lastKnownTweet = False

    tweetContent = open('tweetContentNew.txt','a')
        
    def saveTweets(tweet):
        tweetRaw = json.dumps(tweet)
        tweetParse = json.loads(tweetRaw)

        tweetContent.write(tweetParse['full_text'].encode('utf-8') + '\n' + '\n')
    try:
        for tweet in tweepy.Cursor(API.user_timeline, tweet_mode="extended", screen_name = handle).items():
            if (not tweet.retweeted) and ('RT @' not in tweet.full_text) and (tweet.full_text.rstrip() != lastKnownTweet):
                saveTweets(tweet._json)
            if ('@' in tweet.full_text):
                m = re.search(r'(?<=@)\w+', tweet.full_text)
                if m is not None:
                    userHandles.append(m.group(0))
            if (tweet.full_text.rstrip() == lastKnownTweet):
                break
    except Exception as e:
        print e
        tweetContent.close()
        os.remove("tweetContentNew.txt")
        continue
        
    tweetContent.close()

    with open('tweetContentNew.txt', 'r') as newTweets:
        new_content = newTweets.read()

    if exists:
        with open('./corpora/%s.txt' % handle,'r+') as tweetContentOld:
            lines = tweetContentOld.readlines()
            tweetContentOld.seek(0)
            tweetContentOld.write(new_content)
            for line in lines:
                tweetContentOld.write(line)
            tweetContentOld.close()
    else:
        copyfile("tweetContentNew.txt", "./corpora/%s.txt" % handle)

    os.remove("tweetContentNew.txt")
sys.exit()
