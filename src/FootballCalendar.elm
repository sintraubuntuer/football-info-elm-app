module FootballCalendar exposing
    ( appendToListofGames
    , haveAllGamesInSeason
    , outputView
    , payloadGameDecoder
    , urlForFilteredMatches
    , urlForSeasonRangeInMatchTable
    , urlForWeekRangeInMatchTable
    , weekNrGameNrWeekComparison
    )

import Basics
import Browser
import Debug
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (on, onCheck, onClick, onInput)
import Http
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode as Encode
import LanguageFuncs
    exposing
        ( DisplayLanguage(..)
        , MultiLgWord
        , gtxt
        , gtxt_
        )
import String
import Time
import Types
    exposing
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
        )


getDefaultLeagueId : Int
getDefaultLeagueId =
    2



-- checks if model.games already contains all the games in a given season


haveAllGamesInSeason : Model -> Bool
haveAllGamesInSeason model =
    let
        selSeason =
            Maybe.withDefault -999 model.selectedSeasonId

        lgames =
            filterGamesbyMbSeasonLeague model.games model.selectedSeasonId model.selectedLeague

        nrWeekGames =
            case lgames of
                [] ->
                    0

                headg :: rest ->
                    List.filter (\game -> game.weekNr == headg.weekNr) lgames
                        |> List.length

        nrSeasonGames =
            (nrWeekGames * 2 - 1) * 2 * nrWeekGames

        boolout =
            (List.length lgames /= 0) && (List.length lgames == nrSeasonGames)
    in
    boolout


stringFromBool : Bool -> String
stringFromBool bval =
    if bval then
        "True"

    else
        "False"


appendToListofGames : List Game -> List Game -> List Game
appendToListofGames initialGames lgames =
    case lgames of
        [] ->
            initialGames

        head :: rest ->
            let
                newinitial =
                    List.filter (\game -> (game.weekNr /= head.weekNr) || (game.seasonId /= head.seasonId) || (game.leagueId /= head.leagueId) || (game.homeTeam /= head.homeTeam)) initialGames

                newini2 =
                    [ head ] ++ newinitial
            in
            appendToListofGames newini2 rest


weekNrGameNrWeekComparison : Game -> Game -> Order
weekNrGameNrWeekComparison g1 g2 =
    case compare g1.weekNr g2.weekNr of
        GT ->
            GT

        LT ->
            LT

        EQ ->
            case ( g1.gameNrWeek, g2.gameNrWeek ) of
                ( Just g1NrWeek, Just g2NrWeek ) ->
                    compare g1NrWeek g2NrWeek

                _ ->
                    compare g1.matchDate g2.matchDate


filterGamesbyWeekMbSeasonLeague : List Game -> Int -> Maybe Int -> Int -> List Game
filterGamesbyWeekMbSeasonLeague lgames weeknr mbseasonid leagueid =
    case mbseasonid of
        Nothing ->
            []

        Just seasonid ->
            lgames
                |> List.filter (\game -> game.weekNr == weeknr && game.seasonId == seasonid && game.leagueId == leagueid)


filterGamesbyMbSeasonLeague : List Game -> Maybe Int -> Int -> List Game
filterGamesbyMbSeasonLeague lgames mbseasonid leagueid =
    case mbseasonid of
        Nothing ->
            []

        Just seasonid ->
            lgames
                |> List.filter (\game -> game.seasonId == seasonid && game.leagueId == leagueid)



-- DECODERS/ENCODERS


gameDecoder : Json.Decode.Decoder Game
gameDecoder =
    Json.Decode.succeed Game
        |> Json.Decode.Pipeline.required "matchDate" Json.Decode.string
        |> Json.Decode.Pipeline.custom (Json.Decode.at [ "homeTeam", "shortName" ] Json.Decode.string)
        |> Json.Decode.Pipeline.optional "goalsHomeTeam" (Json.Decode.maybe Json.Decode.int) Nothing
        |> Json.Decode.Pipeline.custom (Json.Decode.at [ "awayTeam", "shortName" ] Json.Decode.string)
        |> Json.Decode.Pipeline.optional "goalsAwayTeam" (Json.Decode.maybe Json.Decode.int) Nothing
        |> Json.Decode.Pipeline.required "weekNr" Json.Decode.int
        |> Json.Decode.Pipeline.optional "gameNrWeek" (Json.Decode.maybe Json.Decode.int) Nothing
        |> Json.Decode.Pipeline.required "season" Json.Decode.int
        |> Json.Decode.Pipeline.required "league" Json.Decode.int


payloadGameDecoder : Json.Decode.Decoder (List Game)
payloadGameDecoder =
    Json.Decode.field "results" (Json.Decode.list gameDecoder)



-- URLS


urlForMatches : String -> String
urlForMatches apiUrl =
    apiUrl ++ "footballmatches/"


urlForFilteredMatches : String -> Int -> Int -> Maybe Int -> String
urlForFilteredMatches apiUrl leagueId seasonId mbweekId =
    case mbweekId of
        Nothing ->
            urlForMatches apiUrl ++ "?season=" ++ String.fromInt seasonId ++ "&league=" ++ String.fromInt leagueId ++ "&ordering=weekNr" ++ "&format=json"

        Just nr ->
            urlForMatches apiUrl ++ "?season=" ++ String.fromInt seasonId ++ "&league=" ++ String.fromInt leagueId ++ "&weekNr=" ++ String.fromInt nr ++ "&ordering=gameNrWeek" ++ "&format=json"


baseUrlForMatchTable : String -> String
baseUrlForMatchTable apiUrl =
    apiUrl


urlForSeasonRangeInMatchTable : String -> Int -> String
urlForSeasonRangeInMatchTable apiUrl leagueId =
    baseUrlForMatchTable apiUrl ++ "getSeasonsForComp/?league=" ++ String.fromInt leagueId ++ "&format=json"


urlForWeekRangeInMatchTable : String -> Int -> Int -> String
urlForWeekRangeInMatchTable apiUrl leagueId seasonId =
    baseUrlForMatchTable apiUrl ++ "getWeekRange/" ++ "?league=" ++ String.fromInt leagueId ++ "&season=" ++ String.fromInt seasonId ++ "&format=json"



-- VIEW


radio : Model -> WeekMode -> String -> List (Html Msg)
radio model mode name =
    [ input
        [ type_ "radio"
        , checked (model.weekmode == mode)
        , onCheck (\_ -> ChangeWeekMode)
        ]
        []
    , text name
    ]


optionGoalsView : Model -> Html Msg
optionGoalsView model =
    div [ class "form-group row" ]
        [ label [ class "col-form-label col-sm-3" ] [ gtxt_ "show goals" model.language ]
        , div [ class "col-sm-9" ]
            (radioOptionGoals model True (gtxt "yes" model.language)
                ++ radioOptionGoals model False (gtxt "no" model.language)
            )
        ]


radioOptionGoals : Model -> Bool -> String -> List (Html Msg)
radioOptionGoals model bool name =
    [ input
        [ type_ "radio"
        , checked (model.showGameResults == bool)
        , onCheck (\_ -> ChangeOptionGoals)
        ]
        []
    , text name
    ]


outputView : Model -> Html Msg
outputView model =
    case model.weekmode of
        SingleWeek ->
            [ outputSingleWeekViewStyled (theFilteredGames model) (Just model.weekNr) model.showGameResults model.language "offset-md-3 col-md-6" "weekgames" ]
                |> wrapInRowDiv

        AllWeeks ->
            outputAllWeeksView model


theFilteredGames : Model -> List Game
theFilteredGames model =
    let
        selectedSeason =
            Maybe.withDefault -999 model.selectedSeasonId

        theGames =
            model.games
                |> List.filter (\game -> game.weekNr == model.weekNr && game.seasonId == selectedSeason && game.leagueId == model.selectedLeague)
    in
    theGames


outputAllWeeksView : Model -> Html Msg
outputAllWeeksView model =
    let
        selectedSeason =
            Maybe.withDefault -999 model.selectedSeasonId

        theFilteredGames_ =
            model.games
                |> List.filter (\game -> game.seasonId == selectedSeason && game.leagueId == model.selectedLeague)
                |> List.sortWith weekNrGameNrWeekComparison

        loflistofWeeks =
            splitListofGames theFilteredGames_ 1
    in
    div [ class "container" ]
        (wrapInRowSepDivsEveryNelems 2 (outputWeekByWeek loflistofWeeks model.showGameResults model.language "offset-md-1 col-md-5 col-sm-12" "manyweekgames"))


outputWeekByWeek : List (List Game) -> Bool -> DisplayLanguage -> String -> String -> List (Html Msg)
outputWeekByWeek llgames showGoals language strClass strTblClass =
    case llgames of
        [ [] ] ->
            [ text "" ]

        [] ->
            [ text "" ]

        lhead :: rest ->
            [ outputSingleWeekViewStyled lhead Nothing showGoals language strClass strTblClass ] ++ outputWeekByWeek rest showGoals language strClass strTblClass


outputSingleWeekView : List Game -> Maybe Int -> DisplayLanguage -> String -> Html Msg
outputSingleWeekView games mbnr language strClass =
    let
        ( lgames, title ) =
            case mbnr of
                Nothing ->
                    case getWeekNrFromListHead games of
                        Nothing ->
                            ( [], "" )

                        Just val ->
                            ( List.filter (\game -> game.weekNr == val) games, gtxt "_Week_" language ++ " " ++ String.fromInt val )

                Just nr ->
                    ( List.filter (\game -> game.weekNr == nr) games, gtxt "_Week_" language ++ " " ++ String.fromInt nr )
    in
    if List.length lgames > 0 then
        div [ classList [ ( strClass, True ), ( "text-center", True ) ] ]
            [ h3 [ class "text-center" ] [ text title ]
            , ul [] <|
                List.map gameToListItem lgames
            ]

    else
        text ""


outputSingleWeekViewStyled : List Game -> Maybe Int -> Bool -> DisplayLanguage -> String -> String -> Html Msg
outputSingleWeekViewStyled games mbnr showGoals language strClass strTblClass =
    let
        ( lgames, title ) =
            case mbnr of
                Nothing ->
                    case getWeekNrFromListHead games of
                        Nothing ->
                            ( [], "" )

                        Just val ->
                            ( List.filter (\game -> game.weekNr == val) games, gtxt "_Week_" language ++ " " ++ String.fromInt val )

                Just nr ->
                    ( List.filter (\game -> game.weekNr == nr) games, gtxt "_Week_" language ++ " " ++ String.fromInt nr )
    in
    if List.length lgames > 0 then
        div [ classList [ ( strClass, True ), ( "text-center", True ) ] ]
            [ h3 [ class "text-center" ] [ text title ]
            , table [ classList [ ( strTblClass, True ), ( "table table-striped", True ) ] ]
                [ thead [] []
                , tbody [] <|
                    List.map (gameToTableRow showGoals) lgames
                ]
            ]

    else
        text ""


gameToTableRow : Bool -> Game -> Html msg
gameToTableRow showGoals game =
    let
        lgoalsOutput =
            if showGoals then
                [ span [ class "score" ]
                    [ text (mbIntToString game.goalsHomeTeam) ]
                , span [ class "score" ]
                    [ text (mbIntToString game.goalsAwayTeam) ]
                ]

            else
                [ span [ class "noScore" ] [ text " - " ] ]
    in
    tr []
        [ td [ class "match" ]
            [ div [ class "matchDate" ]
                [ text (getStrDateFromDate game.matchDate) ]
            , div []
                [ a [ class "teamName" ]
                    [ h4 [] [ text game.homeTeam ] ]
                , a [ class "main-score" ] <|
                    lgoalsOutput
                , a [ class "teamName" ]
                    [ h4 [] [ text game.awayTeam ] ]
                ]
            ]
        ]


getWeekNrFromListHead : List Game -> Maybe Int
getWeekNrFromListHead lgames =
    case List.head lgames of
        Nothing ->
            Nothing

        Just game ->
            Just game.weekNr


gameToListItem : Game -> Html msg
gameToListItem game =
    li []
        [ text (game.homeTeam ++ "  " ++ mbIntToString game.goalsHomeTeam ++ "  -  " ++ mbIntToString game.goalsAwayTeam ++ "  " ++ game.awayTeam)
        ]


mbIntToString : Maybe Int -> String
mbIntToString mbnr =
    case mbnr of
        Nothing ->
            ""

        Just nr ->
            String.fromInt nr


getStrDateFromDate : String -> String
getStrDateFromDate str =
    let
        out =
            String.slice 8 10 str ++ "/" ++ String.slice 5 7 str ++ "/" ++ String.slice 0 4 str ++ "   " ++ String.slice 11 13 str ++ "h" ++ String.slice 14 16 str
    in
    out



-- this is "dangerous" function. Call it only with an ordered ( by weekNr ) List Game
-- safe guard has been added by breaking out if n > 100


splitListofGames : List Game -> Int -> List (List Game)
splitListofGames lgames nr =
    if nr > 100 then
        [ lgames ]

    else
        case lgames of
            [] ->
                []

            _ ->
                takeWhile (\elem -> elem.weekNr == nr) lgames :: splitListofGames (dropWhile (\elem -> elem.weekNr == nr) lgames) (nr + 1)


wrapInContainerAndRowDivs : List (Html Msg) -> Html Msg
wrapInContainerAndRowDivs lelems =
    div [ class "container" ]
        [ div [ class "row" ] lelems
        ]


wrapInRowAndSepDiv : List (Html Msg) -> Html Msg
wrapInRowAndSepDiv lelems =
    div [ class "sepRows" ]
        [ div [ class "row" ] lelems
        ]


wrapInRowDiv : List (Html Msg) -> Html Msg
wrapInRowDiv lelems =
    div [ class "row" ] lelems


wrapInRowDivsEveryNelems : Int -> List (Html Msg) -> List (Html Msg)
wrapInRowDivsEveryNelems nr lelems =
    case lelems of
        [] ->
            []

        _ ->
            wrapInRowDiv (List.take nr lelems) :: wrapInRowDivsEveryNelems nr (List.drop nr lelems)


wrapInRowSepDivsEveryNelems : Int -> List (Html Msg) -> List (Html Msg)
wrapInRowSepDivsEveryNelems nr lelems =
    case lelems of
        [] ->
            []

        _ ->
            wrapInRowAndSepDiv (List.take nr lelems) :: wrapInRowSepDivsEveryNelems nr (List.drop nr lelems)


takeWhile : (a -> Bool) -> List a -> List a
takeWhile predicate xs =
    case xs of
        [] ->
            []

        hd :: tl ->
            if predicate hd then
                hd :: takeWhile predicate tl

            else
                []


dropWhile : (a -> Bool) -> List a -> List a
dropWhile predicate xs =
    case xs of
        [] ->
            []

        hd :: tl ->
            if predicate hd then
                dropWhile predicate tl

            else
                xs
