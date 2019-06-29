module ViewControls exposing
    ( leagueView
    , modeView
    , optionGoalsView
    , outputFetchingDataView
    , radio
    , radioOptionGoals
    , seasonsView
    , submitView
    , tableSizeOptionsView
    , viewAlertMessage
    , weekView
    )

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (on, onCheck, onClick, onInput)
import LanguageFuncs
    exposing
        ( DisplayLanguage(..)
        , MultiLgWord
        , gtxt
        , gtxt_
        )
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


leagueView : Model -> Html Msg
leagueView model =
    div [ class "form-group row" ]
        [ label [ for "leagueSelector", class "col-form-label col-sm-3" ] [ gtxt_ "league" model.language ]
        , div [ class "col-sm-9" ]
            [ select [ class "form-control", onInput ChangeLeague ]
                (List.map (\item -> option [ selected (item.id == model.selectedLeague), value (String.fromInt item.id) ] [ text item.name ]) model.leagues)
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


modeView : Model -> Html Msg
modeView model =
    case model.currentTab of
        CalendarTab ->
            div [ class "form-group row" ]
                [ label [ class "col-form-label col-sm-3" ] [ gtxt_ "output mode" model.language ]
                , div [ class "col-sm-9" ]
                    (radio model.weekmode AllWeeks (gtxt "all weeks" model.language) ChangeWeekMode
                        ++ radio model.weekmode SingleWeek (gtxt "single week" model.language) ChangeWeekMode
                    )
                ]

        StandingsTab ->
            div [] []


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


optionGoalsView : Model -> Html Msg
optionGoalsView model =
    case model.currentTab of
        CalendarTab ->
            div [ class "form-group row" ]
                [ label [ class "col-form-label col-sm-3" ] [ gtxt_ "show goals" model.language ]
                , div [ class "col-sm-9" ]
                    (radioOptionGoals model True (gtxt "yes" model.language)
                        ++ radioOptionGoals model False (gtxt "no" model.language)
                    )
                ]

        StandingsTab ->
            div [] []


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


weekView : Model -> Int -> Html Msg
weekView model maxWeek =
    if model.weekmode == SingleWeek || model.currentTab == StandingsTab then
        div [ class "form-group row" ]
            [ label [ for "weekNrInput", class "col-form-label col-sm-3" ] [ gtxt_ "week nr" model.language ]
            , div [ class "col-sm-9" ]
                [ input
                    [ class "form-control"
                    , type_ "number"
                    , Attr.min "1"
                    , Attr.max (String.fromInt maxWeek)
                    , value (String.fromInt model.weekNr)
                    , onInput ChangeWeekNr
                    ]
                    []
                ]
            ]

    else
        text ""


tableSizeOptionsView : Model -> Html Msg
tableSizeOptionsView model =
    case model.currentTab of
        StandingsTab ->
            div [ class "form-group row" ]
                [ label [ class "col-form-label col-sm-3" ] [ gtxt_ "table size" model.language ]
                , div [ class "col-sm-9" ]
                    (radio model.tablesize FullTable (gtxt "full" model.language) ChangeTableSize
                        ++ radio model.tablesize PartialTable (gtxt "partial" model.language) ChangeTableSize
                    )
                ]

        CalendarTab ->
            div [] []


submitView : Html Msg
submitView =
    div [ class "form-group row" ]
        [ div [ class "offset-sm-3 col-sm-9" ]
            [ button
                [ class "btn btn-success btn-block", onClick Submit ]
                [ text "Submit" ]
            ]
        ]


viewAlertMessage : Maybe String -> Html Msg
viewAlertMessage alertMessage =
    let
        el =
            case alertMessage of
                Just message ->
                    div [ class "alert alert-warning" ]
                        [ text message, span [ class "close", onClick CloseAlert ] [ text "X" ] ]

                Nothing ->
                    text ""
    in
    div [ class "row" ]
        [ div [ class "offset-sm-3 col-sm-9" ] [ el ] ]


outputFetchingDataView : Model -> Html Msg
outputFetchingDataView model =
    let
        strText =
            "Fetching Data .....! "
                |> String.left model.nrInfoChars
    in
    div [ class "offset-md-4 col-md-4" ]
        [ h3 [] [ text strText ] ]
