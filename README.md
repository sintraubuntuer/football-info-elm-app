##  Football-Info-Elm-App

Elm app that displays football info ( fixtures and standings ) with a 'friendly' user interface

It supports several leagues and seasons and has the ability to cache information.

It was designed/configured to work in conjunction with our Football Info Django Rest API but it can easily be adapted to other known football data APIs .
( please let me know if you need help with that )

#### Flags :

You need to set two flags (in index.html) to start the app  
__apiUrl__ :   for instance  "https://footballapintapp.herokuapp.com/footapi/" ,  and  
__language__ : "en" for english or "pt" for portuguese


#### Endpoints :

The API endpoints that the app queries ( and the json responses it expects ) are as follows :

[1]
```
/footapi/weekfootballmatches/season/<sid:int>/league/<lid:int>/weekNr/<wnr:int>/  
```

example :  

/footapi/weekfootballmatches/season/14/league/2/weekNr/34/?format=json

```javascript
{
    "count": 9,
    "next": null,
    "previous": null,
    "results": [
        {
            "matchDate": "2017-05-20T16:00:00+01:00",
            "homeTeam": {
                "id": 22,
                "teamName": "Rio Ave",
                "shortName": "Rio Ave"
            },
            "goalsHomeTeam": 2,
            "awayTeam": {
                "id": 5,
                "teamName": "Belenenses",
                "shortName": "Belenenses"
            },
            "goalsAwayTeam": 0,
            "league": 2,
            "season": 14,
            "weekNr": 34,
            "gameNrWeek": 1,
            "links": {
                "self": "/footapi/footballmatch/3136/",
                "league": "/footapi/league/2/",
                "season": "/footapi/season/14/"
            }
        },
        {
            "matchDate": "2017-05-20T16:00:00+01:00",
            "homeTeam": {
                "id": 11,
                "teamName": "Paços Ferreira",
                "shortName": "P. Ferreira"
            },
            "goalsHomeTeam": 0,
            "awayTeam": {
                "id": 7,
                "teamName": "Marítimo",
                "shortName": "Marítimo"
            },
            "goalsAwayTeam": 0,
            "league": 2,
            "season": 14,
            "weekNr": 34,
            "gameNrWeek": 2,
            "links": {
                "self": "/footapi/footballmatch/3137/",
                "league": "/footapi/league/2/",
                "season": "/footapi/season/14/"
            }
        },
        {
            "matchDate": "2017-05-20T16:00:00+01:00",
            "homeTeam": {
                "id": 21,
                "teamName": "Nacional",
                "shortName": "Nacional"
            },
            "goalsHomeTeam": 1,
            "awayTeam": {
                "id": 13,
                "teamName": "V. Setubal",
                "shortName": "V. Setubal"
            },
            "goalsAwayTeam": 2,
            "league": 2,
            "season": 14,
            "weekNr": 34,
            "gameNrWeek": 3,
            "links": {
                "self": "/footapi/footballmatch/3138/",
                "league": "/footapi/league/2/",
                "season": "/footapi/season/14/"
            }
        },
        (...)
}
```

[2]
```
/footapi/weekstandings/season/<sid:int>/league/<lid:int>/weekNr/<wnr:int>
```

example:  
/footapi/weekstandings/season/10/league/2/weekNr/20/

```javascript
{
    "count": 18,
    "next": null,
    "previous": null,
    "results": [
        {
            "team": 4,
            "teamName": "Benfica",
            "teamShortName": "Benfica",
            "league": 2,
            "leagueName": "Liga Sagres",
            "season": 14,
            "seasonName": "2016-2017",
            "weekNr": 34,
            "weekRank": 1,
            "nrPoints": 82,
            "nrGamesPlayed": 34,
            "nrGamesWon": 25,
            "nrGamesDrawn": 7,
            "nrGamesLost": 2,
            "nrGoalsScored": 72,
            "nrGoalsSuffered": 18,
            "nrHomeGamesPlayed": 17,
            "nrHomeGamesWon": 14,
            "nrHomeGamesLost": 0,
            "nrHomeGamesDrawn": 3,
            "nrGoalsScoredHome": 49,
            "nrGoalsSufferedHome": 9,
            "nrAwayGamesPlayed": 17,
            "nrAwayGamesWon": 11,
            "nrAwayGamesLost": 2,
            "nrAwayGamesDrawn": 4,
            "nrGoalsScoredAway": 23,
            "nrGoalsSufferedAway": 9
        },
        {
            "team": 3,
            "teamName": "FC Porto",
            "teamShortName": "FC Porto",
            "league": 2,
            "leagueName": "Liga Sagres",
            "season": 14,
            "seasonName": "2016-2017",
            "weekNr": 34,
            "weekRank": 2,
            "nrPoints": 76,
            "nrGamesPlayed": 34,
            "nrGamesWon": 22,
            "nrGamesDrawn": 10,
            "nrGamesLost": 2,
            "nrGoalsScored": 71,
            "nrGoalsSuffered": 19,
            "nrHomeGamesPlayed": 17,
            "nrHomeGamesWon": 14,
            "nrHomeGamesLost": 0,
            "nrHomeGamesDrawn": 3,
            "nrGoalsScoredHome": 44,
            "nrGoalsSufferedHome": 9,
            "nrAwayGamesPlayed": 17,
            "nrAwayGamesWon": 8,
            "nrAwayGamesLost": 2,
            "nrAwayGamesDrawn": 7,
            "nrGoalsScoredAway": 27,
            "nrGoalsSufferedAway": 10
        },
        {
            "team": 2,
            "teamName": "Sporting",
            "teamShortName": "Sporting",
            "league": 2,
            "leagueName": "Liga Sagres",
            "season": 14,
            "seasonName": "2016-2017",
            "weekNr": 34,
            "weekRank": 3,
            "nrPoints": 70,
            "nrGamesPlayed": 34,
            "nrGamesWon": 21,
            "nrGamesDrawn": 7,
            "nrGamesLost": 6,
            "nrGoalsScored": 68,
            "nrGoalsSuffered": 36,
            "nrHomeGamesPlayed": 17,
            "nrHomeGamesWon": 12,
            "nrHomeGamesLost": 2,
            "nrHomeGamesDrawn": 3,
            "nrGoalsScoredHome": 37,
            "nrGoalsSufferedHome": 14,
            "nrAwayGamesPlayed": 17,
            "nrAwayGamesWon": 9,
            "nrAwayGamesLost": 4,
            "nrAwayGamesDrawn": 4,
            "nrGoalsScoredAway": 31,
            "nrGoalsSufferedAway": 22
        },
        (...)
}
```

[3]
```
/footapi/getSeasonsForLeague/?league=<lid:int>
```

example:  
/footapi/getSeasonsForLeague/?league=2

```javascript
[
    {
        "season": 14,
        "seasonName": "2016-2017"
    },
    {
        "season": 13,
        "seasonName": "2015-2016"
    },
    {
        "season": 12,
        "seasonName": "2014-2015"
    },
    {
        "season": 11,
        "seasonName": "2013-2014"
    },
    {
        "season": 10,
        "seasonName": "2012-2013"
    },
    {
        "season": 9,
        "seasonName": "2011-2012"
    },
    {
        "season": 8,
        "seasonName": "2010-2011"
    },
    {
        "season": 7,
        "seasonName": "2009-2010"
    },
    {
        "season": 6,
        "seasonName": "2008-2009"
    }
]
```

__[4]__
```
/footapi/getWeekRange/?league=<lid:int>&season=<sid:int>  

  and  

/footapi/getWeekRangeForTblStandings/?league=<lid:int>&season=<sid:int>
```

example:  
/footapi/getWeekRange/?league=2&season=14

```javascript
[
    {
        "weekNr": 34
    },
    {
        "weekNr": 33
    },
    {
        "weekNr": 32
    },
    {
        "weekNr": 31
    },
    {
        "weekNr": 30
    },
    (...)
    {
        "weekNr": 1
    }
]
```    

You can try a demo app at :  
https://footballapintapp.herokuapp.com/demoapp/
