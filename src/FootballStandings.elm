module FootballStandings exposing
    ( appendToListofRankEntries
    , haveAllEntriesForWeek
    , outputRankTableViewStyled
    , payloadRankTableDecoder
    , urlForFilteredStandingsTable
    , urlForSeasonRangeInRankTable
    , urlForWeekRangeInRankTable
    )

import Browser
import Debug
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (on, onCheck, onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, map, succeed)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
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
        )



--order list of records by a given field in a certain way ( Asc , Desc )


orderLRecbyField : OrderCriteria -> OrderType -> List RankTableEntry -> List RankTableEntry
orderLRecbyField ordercriteria ordertype lranktable =
    case ordercriteria of
        OrdRank ->
            case ordertype of
                Asc ->
                    List.sortBy .weekRank lranktable

                Desc ->
                    List.sortBy .weekRank lranktable
                        |> List.reverse

        OrdPoints ->
            case ordertype of
                Asc ->
                    List.sortBy .nrPoints lranktable

                Desc ->
                    List.sortBy .nrPoints lranktable
                        |> List.reverse

        OrdWins ->
            case ordertype of
                Asc ->
                    List.sortBy .nrGamesWon lranktable

                Desc ->
                    List.sortBy .nrGamesWon lranktable
                        |> List.reverse

        OrdDraws ->
            case ordertype of
                Asc ->
                    List.sortBy .nrGamesDrawn lranktable

                Desc ->
                    List.sortBy .nrGamesDrawn lranktable
                        |> List.reverse

        OrdLosses ->
            case ordertype of
                Asc ->
                    List.sortBy .nrGamesLost lranktable

                Desc ->
                    List.sortBy .nrGamesLost lranktable
                        |> List.reverse

        OrdGoalsScored ->
            case ordertype of
                Asc ->
                    List.sortBy .nrGoalsScored lranktable

                Desc ->
                    List.sortBy .nrGoalsScored lranktable
                        |> List.reverse

        OrdGoalsSuffered ->
            case ordertype of
                Asc ->
                    List.sortBy .nrGoalsSuffered lranktable

                Desc ->
                    List.sortBy .nrGoalsSuffered lranktable
                        |> List.reverse


orderLRecbyField_ : CurrentOrder -> List RankTableEntry -> List RankTableEntry
orderLRecbyField_ currentorder lranktable =
    let
        ( ordcriteria, ordtype ) =
            case currentorder of
                CurrentOrder x y ->
                    ( x, y )

        lordered =
            orderLRecbyField ordcriteria ordtype lranktable
    in
    lordered


negateOrdertype : OrderType -> OrderType
negateOrdertype ordtype =
    case ordtype of
        Asc ->
            Desc

        Desc ->
            Asc



-- checks if available sesons for a given competition are already in  'cache'


haveAllEntriesForWeek : Model -> Bool
haveAllEntriesForWeek model =
    let
        lentries =
            filterEntrybyWeekMbSeasonCompetition model.rankTable model.weekNr model.selectedSeasonId model.selectedCompetition

        boolout =
            List.length lentries > 0
    in
    boolout


appendToListofRankEntries : List RankTableEntry -> List RankTableEntry -> List RankTableEntry
appendToListofRankEntries initialRankEntries lranks =
    case lranks of
        [] ->
            initialRankEntries

        head :: rest ->
            let
                newinitial =
                    List.filter (\entry -> entry.weekNr /= head.weekNr || entry.season /= head.season || entry.competition /= head.competition || entry.team /= head.team) initialRankEntries

                newini2 =
                    [ head ] ++ newinitial
            in
            appendToListofRankEntries newini2 rest



-- DECODERS/ENCODERS


rankTableEntryDecoder : Json.Decode.Decoder RankTableEntry
rankTableEntryDecoder =
    Json.Decode.succeed RankTableEntry
        |> Json.Decode.Pipeline.required "team" Json.Decode.int
        |> Json.Decode.Pipeline.required "teamName" Json.Decode.string
        |> Json.Decode.Pipeline.required "teamShortName" Json.Decode.string
        |> Json.Decode.Pipeline.required "competition" Json.Decode.int
        |> Json.Decode.Pipeline.required "competitionName" Json.Decode.string
        |> Json.Decode.Pipeline.required "season" Json.Decode.int
        |> Json.Decode.Pipeline.required "seasonName" Json.Decode.string
        |> Json.Decode.Pipeline.required "weekNr" Json.Decode.int
        |> Json.Decode.Pipeline.required "weekRank" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrPoints" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGamesPlayed" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGamesWon" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGamesDrawn" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGamesLost" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGoalsScored" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGoalsSuffered" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrHomeGamesPlayed" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrHomeGamesWon" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrHomeGamesLost" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrHomeGamesDrawn" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGoalsScoredHome" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGoalsSufferedHome" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrAwayGamesPlayed" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrAwayGamesWon" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrAwayGamesLost" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrAwayGamesDrawn" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGoalsScoredAway" Json.Decode.int
        |> Json.Decode.Pipeline.required "nrGoalsSufferedAway" Json.Decode.int


payloadRankTableDecoder : Json.Decode.Decoder (List RankTableEntry)
payloadRankTableDecoder =
    Json.Decode.field "results" (Json.Decode.list rankTableEntryDecoder)



-- COMMANDS


baseUrlForStandingsTable : String -> String
baseUrlForStandingsTable apiUrl =
    apiUrl


urlForStandingsTable : String -> String
urlForStandingsTable apiUrl =
    baseUrlForStandingsTable apiUrl ++ "seasonstandings/"


urlForFilteredStandingsTable : String -> Int -> Int -> Int -> String
urlForFilteredStandingsTable apiUrl compId seasonId weekId =
    urlForStandingsTable apiUrl ++ "?season=" ++ String.fromInt seasonId ++ "&competition=" ++ String.fromInt compId ++ "&weekNr=" ++ String.fromInt weekId ++ "&ordering=weekRank&format=json"


urlForSeasonRangeInRankTable : String -> Int -> String
urlForSeasonRangeInRankTable apiUrl competitionId =
    baseUrlForStandingsTable apiUrl ++ "getSeasonsForComp/?competition=" ++ String.fromInt competitionId ++ "&format=json"


urlForWeekRangeInRankTable : String -> Int -> Int -> String
urlForWeekRangeInRankTable apiUrl competitionId seasonId =
    baseUrlForStandingsTable apiUrl ++ "getWeekRangeForTblStandings/?competition=" ++ String.fromInt competitionId ++ "&season=" ++ String.fromInt seasonId ++ "&format=json"



-- VIEW


filterEntrybyWeekMbSeasonCompetition : List RankTableEntry -> Int -> Maybe Int -> Int -> List RankTableEntry
filterEntrybyWeekMbSeasonCompetition lentries weeknr mbseasonid competitionid =
    case mbseasonid of
        Nothing ->
            []

        Just seasonid ->
            lentries
                |> List.filter (\entry -> entry.weekNr == weeknr && entry.season == seasonid && entry.competition == competitionid)


outputRankTableViewStyled : Model -> String -> Html Msg
outputRankTableViewStyled model strClass =
    let
        lranktable =
            filterEntrybyWeekMbSeasonCompetition model.rankTable model.weekNr model.selectedSeasonId model.selectedCompetition
                |> orderLRecbyField_ model.currentorder

        ( compName, seasonName ) =
            case getCompAndSeasonNameFromListHead lranktable of
                Nothing ->
                    ( "", "" )

                Just ( a, b ) ->
                    ( a, b )

        strTitle =
            gtxt "_Standings-Season_" model.language ++ seasonName ++ " - " ++ compName
    in
    if List.length lranktable > 0 then
        [ div [ class (strClass ++ " text-center"), align "center" ]
            [ table [ class "tableRank" ]
                [ thead [] <|
                    getListTableRankHeaders strTitle model.currentorder model.tablesize model.language
                , tbody [] <|
                    List.map (rankTableEntryToTableRow model.tablesize) lranktable
                ]
            ]
        ]
            |> wrapInContainerAndRowDivs

    else
        [ text "" ]
            |> wrapInContainerAndRowDivs


getCompAndSeasonNameFromListHead : List RankTableEntry -> Maybe ( String, String )
getCompAndSeasonNameFromListHead lranktable =
    case List.head lranktable of
        Nothing ->
            Nothing

        Just entry ->
            Just ( entry.competitionName, entry.seasonName )


getOrderArrows : OrderCriteria -> CurrentOrder -> Html Msg
getOrderArrows ordercriteria currentorder =
    let
        ( classUp, upOrder ) =
            if currentorder == CurrentOrder ordercriteria Asc then
                ( "active-arrow-up", Desc )

            else
                ( "arrow-up", Asc )

        ( classDown, downOrder ) =
            if currentorder == CurrentOrder ordercriteria Desc then
                ( "active-arrow-down", Asc )

            else
                ( "arrow-down", Desc )
    in
    span [ class "orderingtriangles" ]
        [ div [ class classUp, onClick (NewTableOrder ordercriteria upOrder) ] []
        , div [ class classDown, onClick (NewTableOrder ordercriteria downOrder) ] []
        ]


getListTableRankHeaders : String -> CurrentOrder -> TableSize -> DisplayLanguage -> List (Html Msg)
getListTableRankHeaders strTitle currentorder tablesize language =
    let
        nrColumns =
            if tablesize == FullTable then
                21

            else
                9

        partialHeadersRowOne =
            [ th [ rowspan 2, class "theaders" ] [ gtxt_ "_Pos_" language, getOrderArrows OrdRank currentorder ]
            , th [ rowspan 2, class "theaders" ] [ gtxt_ "_Equipas_" language ]
            , th [ rowspan 2, class "theaders" ] [ gtxt_ "_Pts_" language, getOrderArrows OrdPoints currentorder ]
            , th [ colspan 6, class "theaders" ] [ gtxt_ "_Total_" language ]
            ]

        homeAwayHeadersRowOne =
            [ th [ colspan 6, class "theaders" ] [ gtxt_ "_Casa_" language ]
            , th [ colspan 6, class "theaders" ] [ gtxt_ "_Fora_" language ]
            ]

        partialHeadersRowTwo =
            [ th [ class "teamStatsHeader" ]
                [ gtxt_ "_Jg_" language
                , span [ class "orderingtriangles" ]
                    [ div [ class "hidden-arrow-up" ] []
                    , div [ class "hidden-arrow-down" ] []
                    ]
                ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_V_" language, getOrderArrows OrdWins currentorder ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_E_" language, getOrderArrows OrdDraws currentorder ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_D_" language, getOrderArrows OrdLosses currentorder ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_GM_" language, getOrderArrows OrdGoalsScored currentorder ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_GS_" language, getOrderArrows OrdGoalsSuffered currentorder ]
            ]

        homeAwayHeadersRowTwo =
            [ th [ class "teamStatsHeader" ] [ gtxt_ "_Jg_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_V_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_E_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_D_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_GM_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_GS_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_Jg_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_V_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_E_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_D_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_GM_" language ]
            , th [ class "teamStatsHeader" ] [ gtxt_ "_GS_" language ]
            ]

        ( rowOne, rowTwo ) =
            if tablesize == FullTable then
                ( partialHeadersRowOne ++ homeAwayHeadersRowOne, partialHeadersRowTwo ++ homeAwayHeadersRowTwo )

            else
                ( partialHeadersRowOne, partialHeadersRowTwo )
    in
    [ tr []
        [ th [ colspan nrColumns, class "tHeaderTitle" ] [ text strTitle ]
        ]
    , tr [] <|
        rowOne
    , tr [] <|
        rowTwo
    ]


rankTableEntryToTableRow : TableSize -> RankTableEntry -> Html msg
rankTableEntryToTableRow tablesize rtentry =
    let
        lpartialTableCells =
            [ td [ class "teamRank" ] [ text (String.fromInt rtentry.weekRank) ]
            , td [ class "teamName" ] [ text rtentry.teamShortName ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrPoints) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGamesPlayed) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGamesWon) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGamesDrawn) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGamesLost) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGoalsScored) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGoalsSuffered) ]
            ]

        lHomeAwayTableCells =
            [ td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrHomeGamesPlayed) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrHomeGamesWon) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrHomeGamesDrawn) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrHomeGamesLost) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGoalsScoredHome) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGoalsSufferedHome) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrAwayGamesPlayed) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrAwayGamesWon) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrAwayGamesDrawn) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrAwayGamesLost) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGoalsScoredAway) ]
            , td [ class "teamRankStats" ] [ text (String.fromInt rtentry.nrGoalsSufferedAway) ]
            ]

        ltableRow =
            if tablesize == FullTable then
                lpartialTableCells ++ lHomeAwayTableCells

            else
                lpartialTableCells
    in
    tr [] <|
        ltableRow


competitionView : Model -> Html Msg
competitionView model =
    div [ class "form-group row" ]
        [ label [ for "competitionSelector", class "col-form-label col-sm-3" ] [ gtxt_ "compet." model.language ]
        , div [ class "col-sm-9" ]
            [ select [ class "form-control", onInput ChangeCompetition ]
                (List.map (\item -> option [ selected (item.id == model.selectedCompetition), value (String.fromInt item.id) ] [ text item.name ]) model.competitions)
            ]
        ]


seasonsView : Model -> Html Msg
seasonsView model =
    div [ class "form-group row" ]
        [ label [ for "seasonsInput", class "col-form-label col-sm-3" ] [ gtxt_ "season" model.language ]
        , div [ class "col-sm-9" ]
            [ select [ class "form-control", onInput ChangeSeason ]
                (List.map (\item -> option [ selected (Just item.seasonId == model.selectedSeasonId), value (String.fromInt item.seasonId) ] [ text item.seasonName ]) model.seasonRange)
            ]
        ]


radio : a -> a -> String -> Msg -> List (Html Msg)
radio frommodel opt name msg =
    [ input
        [ type_ "radio"
        , checked (frommodel == opt)
        , onCheck (\_ -> msg)
        ]
        []
    , text name
    ]


tableSizeOptionsView : Model -> Html Msg
tableSizeOptionsView model =
    div [ class "form-group row" ]
        [ label [ class "col-form-label col-sm-3" ] [ gtxt_ "table size" model.language ]
        , div [ class "col-sm-9" ]
            (radio model.tablesize FullTable (gtxt "full" model.language) ChangeTableSize
                ++ radio model.tablesize PartialTable (gtxt "partial" model.language) ChangeTableSize
            )
        ]


submitView : Html Msg
submitView =
    div [ class "form-group row" ]
        [ div [ class "offset-sm-3 col-sm-9" ]
            [ button
                [ class "btn btn-success btn-block", onClick Submit ]
                [ text "Submit" ]
            ]
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
