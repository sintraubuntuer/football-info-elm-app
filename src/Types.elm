module Types exposing
    ( CurrentOrder(..)
    , CurrentTab(..)
    , Game
    , League
    , LeagueId
    , Model
    , Msg(..)
    , OrderCriteria(..)
    , OrderType(..)
    , PresentStatus(..)
    , RankTableEntry
    , Season
    , SeasonId
    , TabId
    , TableSize(..)
    , WeekMode(..)
    , calendarTab
    , standingsTab
    )

import Dict
import Http
import LanguageFuncs
    exposing
        ( DisplayLanguage(..)
        , MultiLgWord
        , gtxt
        , gtxt_
        )
import Time


type CurrentTab
    = CalendarTab
    | StandingsTab


calendarTab : TabId
calendarTab =
    1


standingsTab : TabId
standingsTab =
    2


type OrderType
    = Asc
    | Desc


type OrderCriteria
    = OrdRank
    | OrdPoints
    | OrdWins
    | OrdDraws
    | OrdLosses
    | OrdGoalsScored
    | OrdGoalsSuffered


type CurrentOrder
    = CurrentOrder OrderCriteria OrderType


type TableSize
    = FullTable
    | PartialTable


type PresentStatus
    = NoData
    | ShowingData
    | FetchingData


type alias League =
    { id : Int
    , name : String
    }


type alias Season =
    { seasonId : Int
    , seasonName : String
    }


type WeekMode
    = SingleWeek
    | AllWeeks


type alias LeagueId =
    Int


type alias SeasonId =
    Int


type alias Game =
    { matchDate : String
    , homeTeam : String
    , goalsHomeTeam : Maybe Int
    , awayTeam : String
    , goalsAwayTeam : Maybe Int
    , weekNr : Int
    , gameNrWeek : Maybe Int
    , seasonId : Int
    , leagueId : Int
    }


type alias RankTableEntry =
    { team : Int
    , teamName : String
    , teamShortName : String
    , league : Int
    , leagueName : String
    , season : Int
    , seasonName : String
    , weekNr : Int
    , weekRank : Int
    , nrPoints : Int
    , nrGamesPlayed : Int
    , nrGamesWon : Int
    , nrGamesDrawn : Int
    , nrGamesLost : Int
    , nrGoalsScored : Int
    , nrGoalsSuffered : Int
    , nrHomeGamesPlayed : Int
    , nrHomeGamesWon : Int
    , nrHomeGamesLost : Int
    , nrHomeGamesDrawn : Int
    , nrGoalsScoredHome : Int
    , nrGoalsSufferedHome : Int
    , nrAwayGamesPlayed : Int
    , nrAwayGamesWon : Int
    , nrAwayGamesLost : Int
    , nrAwayGamesDrawn : Int
    , nrGoalsScoredAway : Int
    , nrGoalsSufferedAway : Int
    }


type alias TabId =
    Int


type Msg
    = Noop
    | ChangeTab CurrentTab
    | ChangeSeason String
    | ChangeLeague String
    | ChangeWeekMode
    | ChangeWeekNr String
    | ChangeOptionGoals
    | ChangeTableSize
    | GetWeekRangeIfNotInCache
    | GetSeasonRangeIfNotInCache
    | NewSeasonRange (Result.Result Http.Error (List Season))
    | NewWeekRange (Result.Result Http.Error (List Int))
    | NewGames (Result.Result Http.Error (List Game))
    | NewRankTable (Result.Result Http.Error (List RankTableEntry))
    | NewFetchingInfo Time.Posix
    | NewTableOrder OrderCriteria OrderType
    | CloseAlert
    | NewDisplayLanguage DisplayLanguage
    | PresentNewInfo
    | Submit


type alias Model =
    { presentStatus : PresentStatus
    , currentTab : CurrentTab
    , leagues : List League
    , selectedLeague : Int
    , seasonRange : List Season
    , cacheSeasonRanges : Dict.Dict LeagueId (List Season)
    , selectedSeasonId : Maybe Int
    , weekmode : WeekMode
    , weekNr : Int
    , cacheWeekRange : Dict.Dict ( LeagueId, SeasonId, TabId ) Int
    , games : List Game
    , showGameResults : Bool
    , rankTable : List RankTableEntry
    , currentorder : CurrentOrder
    , tablesize : TableSize
    , nrInfoChars : Int
    , alertMessage : Maybe String
    , language : DisplayLanguage
    , apiUrl : String
    }
