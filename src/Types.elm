module Types exposing
    ( Competition
    , CompetitionId
    , CurrentOrder(..)
    , CurrentTab(..)
    , Game
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


type alias Competition =
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


type alias CompetitionId =
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
    , competitionId : Int
    }


type alias RankTableEntry =
    { team : Int
    , teamName : String
    , teamShortName : String
    , competition : Int
    , competitionName : String
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
    | ChangeCompetition String
    | ChangeWeekMode
    | ChangeWeekNr String
    | ChangeOptionGoals
    | ChangeTableSize
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
    , competitions : List Competition
    , selectedCompetition : Int
    , seasonRange : List Season
    , cacheSeasonRanges : Dict.Dict CompetitionId (List Season)
    , selectedSeasonId : Maybe Int
    , weekmode : WeekMode
    , weekNr : Int
    , cacheWeekRange : Dict.Dict ( CompetitionId, SeasonId, TabId ) Int
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
