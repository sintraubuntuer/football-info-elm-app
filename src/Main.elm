module Main exposing (main)

import Browser
import Dict exposing (Dict)
import FootballCalendar
import FootballStandings
import Html exposing (Html, a, br, div, h2, h3, h5, li, nav, span, text, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode
import LanguageFuncs
    exposing
        ( DisplayLanguage(..)
        , MultiLgWord
        , gtxt
        , gtxt_
        )
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
        , calendarTab
        , standingsTab
        )
import ViewControls


initialcurrentorder : CurrentOrder
initialcurrentorder =
    CurrentOrder OrdRank Asc


getDefaultLeagueId : Int
getDefaultLeagueId =
    2


getSeasonIdFromSeasonRangeHead : List Season -> Maybe Int
getSeasonIdFromSeasonRangeHead lseasons =
    let
        srange =
            lseasons
                |> List.sortBy .seasonId
                |> List.reverse
    in
    case List.head srange of
        Just s ->
            Just s.seasonId

        Nothing ->
            Nothing


isSeasonIdinSeasonRange : Int -> List Season -> Bool
isSeasonIdinSeasonRange id lseasons =
    let
        l =
            List.map .seasonId lseasons
    in
    List.member id l


getInitialModel : Maybe String -> Maybe String -> Model
getInitialModel mbUrl mbLanguage =
    let
        lang =
            case mbLanguage of
                Just "pt" ->
                    DisplayPortuguese

                _ ->
                    DisplayEnglish
    in
    { presentStatus = NoData
    , currentTab = CalendarTab
    , leagues = [ League 1 "Primeira Liga", League 2 "Liga Sagres" ]
    , selectedLeague = getDefaultLeagueId
    , seasonRange = []
    , cacheSeasonRanges = Dict.empty
    , selectedSeasonId = Nothing
    , weekmode = SingleWeek
    , weekNr = 34
    , cacheWeekRange = Dict.empty
    , games = []
    , showGameResults = True
    , rankTable = []
    , currentorder = initialcurrentorder
    , tablesize = FullTable
    , nrInfoChars = 15
    , alertMessage = Nothing
    , language = lang
    , apiUrl = mbUrl |> Maybe.withDefault ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        ChangeTab tab ->
            let
                newModel =
                    { model | currentTab = tab }
            in
            update GetWeekRangeIfNotInCache newModel

        NewDisplayLanguage displaylanguage ->
            ( { model | language = displaylanguage }, Cmd.none )

        ChangeLeague val ->
            let
                newLeague =
                    val
                        |> String.toInt
                        |> Result.fromMaybe "couldn't convert to Int"
                        |> Result.withDefault getDefaultLeagueId

                newModel =
                    { model | selectedLeague = newLeague }
            in
            update GetSeasonRangeIfNotInCache newModel

        GetSeasonRangeIfNotInCache ->
            let
                thelSeasons =
                    Dict.get model.selectedLeague model.cacheSeasonRanges

                ( newModel, cmds ) =
                    case thelSeasons of
                        -- only gets season range from server if not present in model cache
                        Nothing ->
                            ( model, getSeasonRange model.apiUrl model.selectedLeague model.currentTab )

                        Just lseasons ->
                            update (NewSeasonRange (Ok lseasons)) model
            in
            ( newModel, cmds )

        ChangeSeason val ->
            let
                mbNewSeason =
                    String.toInt val
            in
            case mbNewSeason of
                Nothing ->
                    ( model, Cmd.none )

                Just nr ->
                    update GetWeekRangeIfNotInCache { model | selectedSeasonId = Just nr }

        ChangeWeekMode ->
            let
                newModel =
                    case model.weekmode of
                        AllWeeks ->
                            { model | weekmode = SingleWeek }

                        SingleWeek ->
                            { model | weekmode = AllWeeks }
            in
            update PresentNewInfo newModel

        ChangeOptionGoals ->
            ( { model | showGameResults = not model.showGameResults }, Cmd.none )

        ChangeTableSize ->
            case model.tablesize of
                FullTable ->
                    ( { model | tablesize = PartialTable }, Cmd.none )

                PartialTable ->
                    ( { model | tablesize = FullTable }, Cmd.none )

        ChangeWeekNr val ->
            let
                newWeek =
                    val
                        |> String.toInt
                        |> Result.fromMaybe "couldn't convert to Int"
                        |> Result.withDefault 1

                newModel =
                    { model | weekNr = newWeek }
            in
            update PresentNewInfo newModel

        NewSeasonRange (Ok lseason) ->
            let
                selectedSeason =
                    case model.selectedSeasonId of
                        Just s ->
                            if isSeasonIdinSeasonRange s lseason then
                                Just s

                            else
                                getSeasonIdFromSeasonRangeHead lseason

                        Nothing ->
                            getSeasonIdFromSeasonRangeHead lseason

                newCacheSRange =
                    checkAndGetNewSeasonRangeCache model.selectedLeague lseason model.cacheSeasonRanges

                newModel1 =
                    { model
                        | seasonRange = lseason
                        , cacheSeasonRanges = newCacheSRange
                        , selectedSeasonId = selectedSeason
                    }
            in
            update GetWeekRangeIfNotInCache newModel1

        NewSeasonRange (Err error) ->
            let
                errMessage =
                    "error while fetching season range info : " ++ errorToString error
            in
            ( { model
                | presentStatus = NoData
                , alertMessage = Just errMessage
                , seasonRange = []
                , selectedSeasonId = Nothing
              }
            , Cmd.none
            )

        GetWeekRangeIfNotInCache ->
            case model.selectedSeasonId of
                Nothing ->
                    ( model, Cmd.none )

                Just sId ->
                    let
                        dictKey =
                            ( model.selectedLeague, sId, model.currentTab |> toTabId )

                        mbCachedWeekTuple =
                            Dict.get dictKey model.cacheWeekRange
                    in
                    case mbCachedWeekTuple of
                        Nothing ->
                            ( model, getWeekRange model.apiUrl model.selectedLeague sId model.currentTab )

                        Just ( minWeek, maxWeek ) ->
                            update (NewWeekRange (Ok (List.range minWeek maxWeek))) model

        NewWeekRange (Ok lweeks) ->
            let
                mbMaxWeek =
                    List.maximum lweeks

                mbMinWeek =
                    List.minimum lweeks

                selectedWeek =
                    case mbMaxWeek of
                        Nothing ->
                            model.weekNr

                        Just mw ->
                            if mw >= model.weekNr then
                                model.weekNr

                            else
                                mw

                newCacheWeekRange =
                    case ( mbMinWeek, mbMaxWeek ) of
                        ( Just minWeek, Just maxWeek ) ->
                            case model.currentTab of
                                CalendarTab ->
                                    checkAndGetNewWeekRangeCache model.selectedLeague model.selectedSeasonId minWeek maxWeek calendarTab model.cacheWeekRange

                                StandingsTab ->
                                    checkAndGetNewWeekRangeCache model.selectedLeague model.selectedSeasonId minWeek maxWeek standingsTab model.cacheWeekRange

                        _ ->
                            model.cacheWeekRange

                newModel =
                    { model
                        | weekNr = selectedWeek
                        , cacheWeekRange = newCacheWeekRange
                    }
            in
            update PresentNewInfo newModel

        NewWeekRange (Err error) ->
            let
                errMessage =
                    "error while fetching week range info : " ++ errorToString error
            in
            ( { model | alertMessage = Just errMessage }, Cmd.none )

        NewGames (Ok lgames) ->
            let
                newlgames =
                    FootballCalendar.appendToListofGames model.games lgames
                        |> List.sortWith FootballCalendar.weekNrGameNrWeekComparison
            in
            if List.length lgames > 0 then
                ( { model | games = newlgames, presentStatus = ShowingData, alertMessage = Nothing }, Cmd.none )

            else
                ( { model | presentStatus = NoData, alertMessage = Just "No Data was found !" }, Cmd.none )

        NewGames (Err error) ->
            let
                errMessage =
                    "error while fetching games info : " ++ errorToString error
            in
            ( { model | games = [], presentStatus = NoData, alertMessage = Just errMessage }, Cmd.none )

        NewRankTable (Ok lranks) ->
            let
                newlranks =
                    FootballStandings.appendToListofRankEntries model.rankTable lranks
            in
            if List.length lranks > 0 then
                ( { model | rankTable = newlranks, presentStatus = ShowingData, alertMessage = Nothing }, Cmd.none )

            else
                ( { model | presentStatus = NoData, alertMessage = Just "No Data was found !" }, Cmd.none )

        NewRankTable (Err error) ->
            let
                errMessage =
                    "error trying to get weekly ranks info : " ++ errorToString error
            in
            ( { model | rankTable = [], presentStatus = NoData, alertMessage = Just errMessage }, Cmd.none )

        NewTableOrder ordercriteria ordertype ->
            ( { model
                | currentorder = CurrentOrder ordercriteria ordertype
              }
            , Cmd.none
            )

        NewFetchingInfo posixtime ->
            ( { model
                | nrInfoChars = 15 - Basics.remainderBy 4 (Time.posixToMillis posixtime // 200)
              }
            , Cmd.none
            )

        CloseAlert ->
            ( { model | alertMessage = Nothing }, Cmd.none )

        PresentNewInfo ->
            case model.currentTab of
                StandingsTab ->
                    let
                        ( newModel, cmds ) =
                            if FootballStandings.haveAllEntriesForWeek model then
                                ( { model
                                    | alertMessage = Nothing
                                    , currentorder = CurrentOrder OrdRank Asc
                                  }
                                , Cmd.none
                                )

                            else
                                update Submit model
                    in
                    ( newModel, cmds )

                CalendarTab ->
                    case model.weekmode of
                        SingleWeek ->
                            let
                                selSeason =
                                    Maybe.withDefault -999 model.selectedSeasonId

                                selGames =
                                    model.games
                                        |> List.filter (\game -> game.weekNr == model.weekNr && game.seasonId == selSeason && game.leagueId == model.selectedLeague)

                                ( newModel, cmds ) =
                                    if List.length selGames == 0 then
                                        update Submit model

                                    else
                                        ( { model | alertMessage = Nothing }, Cmd.none )
                            in
                            ( newModel, cmds )

                        AllWeeks ->
                            let
                                ( newModel, cmds ) =
                                    if FootballCalendar.haveAllGamesInSeason model then
                                        ( { model | alertMessage = Nothing }, Cmd.none )

                                    else
                                        update Submit model
                            in
                            ( newModel, cmds )

        Submit ->
            let
                mbweek =
                    case model.weekmode of
                        AllWeeks ->
                            Nothing

                        SingleWeek ->
                            Just model.weekNr

                newCmd sId =
                    case model.currentTab of
                        CalendarTab ->
                            getGames model.apiUrl model.selectedLeague sId mbweek

                        StandingsTab ->
                            getRankTable model.apiUrl model.selectedLeague sId model.weekNr
            in
            case model.selectedSeasonId of
                Just seasonId ->
                    ( { model
                        | presentStatus = FetchingData
                        , alertMessage = Nothing
                        , currentorder = CurrentOrder OrdRank Asc
                      }
                    , newCmd seasonId
                    )

                Nothing ->
                    ( { model
                        | presentStatus = NoData
                        , alertMessage = Just "no season selected"
                      }
                    , Cmd.none
                    )


toTabId : CurrentTab -> TabId
toTabId currTab =
    case currTab of
        StandingsTab ->
            standingsTab

        CalendarTab ->
            calendarTab


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl str1 ->
            "BadUrl : " ++ str1

        Http.Timeout ->
            "Timeout "

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus bsint ->
            "BadStatus : " ++ String.fromInt bsint

        Http.BadBody str2 ->
            "BadBody : " ++ str2



-- Commands


getSeasonRange : String -> Int -> CurrentTab -> Cmd Msg
getSeasonRange apiUrl leagueId currentTab =
    let
        ( theUrlFunc, theMsg ) =
            case currentTab of
                CalendarTab ->
                    ( FootballCalendar.urlForSeasonRangeInMatchTable, NewSeasonRange )

                StandingsTab ->
                    ( FootballStandings.urlForSeasonRangeInRankTable, NewSeasonRange )
    in
    Http.request
        { method = "GET"
        , headers =
            []
        , url = theUrlFunc apiUrl leagueId
        , body = Http.emptyBody
        , expect = Http.expectJson theMsg (Json.Decode.list seasonsRangeDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


getWeekRange : String -> Int -> Int -> CurrentTab -> Cmd Msg
getWeekRange apiUrl leagueId seasonId currentTab =
    let
        ( theUrlFunc, theMsg ) =
            case currentTab of
                CalendarTab ->
                    ( FootballCalendar.urlForWeekRangeInMatchTable, NewWeekRange )

                StandingsTab ->
                    ( FootballStandings.urlForWeekRangeInRankTable, NewWeekRange )
    in
    Http.request
        { method = "GET"
        , headers = []
        , url = theUrlFunc apiUrl leagueId seasonId
        , body = Http.emptyBody
        , expect = Http.expectJson theMsg (Json.Decode.list weekRangeDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


getRankTable : String -> Int -> Int -> Int -> Cmd Msg
getRankTable apiUrl compId seasonId weekId =
    Http.request
        { method = "GET"
        , headers =
            [--Http.header "Origin" "http://127.0.0.1"
             --, Http.header "Access-Control-Request-Method" "GET"
             --, Http.header "Access-Control-Request-Headers" "X-Custom-Header"
            ]
        , url = FootballStandings.urlForFilteredStandingsTable apiUrl compId seasonId weekId
        , body = Http.emptyBody
        , expect = Http.expectJson NewRankTable FootballStandings.payloadRankTableDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getIfPossibleRankTable : String -> Int -> Maybe Int -> Int -> Cmd Msg
getIfPossibleRankTable apiUrl compId mbseasonId weekId =
    case mbseasonId of
        Nothing ->
            Cmd.none

        Just sid ->
            getRankTable apiUrl compId sid weekId


getGames : String -> Int -> Int -> Maybe Int -> Cmd Msg
getGames apiUrl compId seasonId mbweekId =
    Http.request
        { method = "GET"
        , headers = []
        , url = FootballCalendar.urlForFilteredMatches apiUrl compId seasonId mbweekId
        , body = Http.emptyBody
        , expect = Http.expectJson NewGames FootballCalendar.payloadGameDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getIfPossibleGames : String -> Int -> Maybe Int -> Maybe Int -> Cmd Msg
getIfPossibleGames apiUrl compId mbseasonId mbweekId =
    case mbseasonId of
        Nothing ->
            Cmd.none

        Just sid ->
            getGames apiUrl compId sid mbweekId



-- DECODERS


seasonsRangeDecoder : Json.Decode.Decoder Season
seasonsRangeDecoder =
    Json.Decode.map2 Season
        (Json.Decode.field "season" Json.Decode.int)
        (Json.Decode.field "seasonName" Json.Decode.string)


weekRangeDecoder : Json.Decode.Decoder Int
weekRangeDecoder =
    Json.Decode.field "weekNr" Json.Decode.int


checkAndGetNewSeasonRangeCache : Int -> List Season -> Dict Int (List Season) -> Dict Int (List Season)
checkAndGetNewSeasonRangeCache leagueId lseasons dCacheSeasons =
    let
        lseason =
            Dict.get leagueId dCacheSeasons

        newCacheSeasonRange =
            case lseason of
                Nothing ->
                    Dict.insert leagueId lseasons dCacheSeasons

                _ ->
                    dCacheSeasons
    in
    newCacheSeasonRange


checkAndGetNewWeekRangeCache : Int -> Maybe Int -> Int -> Int -> TabId -> Dict ( Int, Int, TabId ) ( Int, Int ) -> Dict ( Int, Int, TabId ) ( Int, Int )
checkAndGetNewWeekRangeCache leagueId mbseasonId minweek maxweek tabId dCacheWeekRange =
    case mbseasonId of
        Just seasonId ->
            let
                currWeekTuple =
                    Dict.get ( leagueId, seasonId, tabId ) dCacheWeekRange

                newCacheDict =
                    case currWeekTuple of
                        Nothing ->
                            Dict.insert ( leagueId, seasonId, tabId ) ( minweek, maxweek ) dCacheWeekRange

                        _ ->
                            dCacheWeekRange
            in
            newCacheDict

        Nothing ->
            dCacheWeekRange



-- VIEW


view : Model -> Html Msg
view model =
    if model.apiUrl /= "" then
        div []
            [ div [] [ renderHeaders model ]
            , br [] []
            , div [] [ renderTabContent model ]
            ]

    else
        div []
            [ h3 [] [ text "Please Provide flags with a valid API Url" ]
            ]


renderHeaders : Model -> Html Msg
renderHeaders model =
    div []
        [ div [ class "container" ]
            [ div [ class "row" ]
                [ div [ class "offset-md-3 col-md-6" ]
                    [ ul [ class "nav nav-tabs" ]
                        [ li [ class "nav-item" ]
                            [ a
                                [ class "nav-link"
                                , onClick (ChangeTab CalendarTab)
                                , classList [ ( "active", model.currentTab == CalendarTab ) ]
                                ]
                                [ LanguageFuncs.gtxt_ "calendar" model.language ]
                            ]
                        , li [ class "nav-item" ]
                            [ a
                                [ class "nav-link"
                                , onClick (ChangeTab StandingsTab)
                                , classList [ ( "active", model.currentTab == StandingsTab ) ]
                                ]
                                [ LanguageFuncs.gtxt_ "standings" model.language ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


renderTabContent : Model -> Html Msg
renderTabContent model =
    div []
        [ viewCommonControls model
        , br [] []
        , br [] []
        , if model.presentStatus == ShowingData || model.presentStatus == NoData then
            case model.currentTab of
                CalendarTab ->
                    FootballCalendar.outputView model

                StandingsTab ->
                    FootballStandings.outputRankTableViewStyled model "offset-md-2 col-md-8"

          else
            ViewControls.outputFetchingDataView model
        , br [] []
        , br [] []
        , div [] [ br [] [], br [] [] ]
        ]


viewCommonControls : Model -> Html Msg
viewCommonControls model =
    div []
        [ div [ class "container" ]
            [ div [ class "row" ]
                [ div [ class "offset-md-3 col-md-6" ]
                    [ span [ class "text-center" ] [ titleView model ]
                    , br [] []
                    , div [ class "container" ]
                        [ ViewControls.leagueView model
                        , ViewControls.seasonsView model
                        , ViewControls.modeView model
                        , ViewControls.weekView model (getMaxWeek model)
                        , ViewControls.optionGoalsView model
                        , ViewControls.tableSizeOptionsView model
                        , ViewControls.submitView
                        , ViewControls.viewAlertMessage model.alertMessage
                        ]
                    ]
                ]
            ]
        ]


getMaxWeek : Model -> Int
getMaxWeek model =
    let
        tabId =
            toTabId model.currentTab
    in
    case model.selectedSeasonId of
        Just sid ->
            Dict.get ( model.selectedLeague, sid, tabId ) model.cacheWeekRange
                |> Maybe.withDefault ( 1, 34 )
                |> Tuple.second

        Nothing ->
            34


titleView : Model -> Html Msg
titleView model =
    let
        title =
            case model.currentTab of
                CalendarTab ->
                    "football Calendar"

                StandingsTab ->
                    "standings"
    in
    div []
        [ h2 []
            [ LanguageFuncs.gtxt_ title model.language
            ]
        ]



-- INIT


flagsDecoder : Json.Decode.Decoder FlagsDecoded
flagsDecoder =
    Json.Decode.map2 FlagsDecoded
        (Json.Decode.field "apiUrl" Json.Decode.string)
        (Json.Decode.field "language" Json.Decode.string)


initFunc : Flags -> ( Model, Cmd Msg )
initFunc flagsToDec =
    let
        initFuncHelper : Maybe String -> Maybe String -> ( Model, Cmd Msg )
        initFuncHelper mbUrl mbLanguage =
            let
                initialModel =
                    getInitialModel mbUrl mbLanguage

                cmdBatch1 =
                    case ( initialModel.currentTab, mbUrl ) of
                        ( CalendarTab, Just theUrl ) ->
                            [ getSeasonRange theUrl initialModel.selectedLeague CalendarTab
                            , getIfPossibleGames theUrl initialModel.selectedLeague initialModel.selectedSeasonId (Just initialModel.weekNr)
                            ]

                        _ ->
                            []

                cmdBatch2 =
                    case ( initialModel.currentTab, mbUrl ) of
                        ( StandingsTab, Just theUrl ) ->
                            [ getSeasonRange theUrl initialModel.selectedLeague StandingsTab
                            , getIfPossibleRankTable theUrl initialModel.selectedLeague initialModel.selectedSeasonId initialModel.weekNr
                            ]

                        _ ->
                            []
            in
            ( initialModel
            , Cmd.batch
                (cmdBatch1 ++ cmdBatch2)
            )
    in
    case Json.Decode.decodeValue flagsDecoder flagsToDec of
        Err _ ->
            initFuncHelper Nothing Nothing

        Ok flags ->
            initFuncHelper (Just flags.apiUrl) (Just flags.language)


type alias FlagsDecoded =
    { apiUrl : String
    , language : String
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.presentStatus == FetchingData then
        Time.every 200 NewFetchingInfo

    else
        Sub.none


type alias Flags =
    Json.Decode.Value


main : Program Flags Model Msg
main =
    Browser.element
        { init = initFunc
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
