module LanguageFuncs exposing
    ( DisplayLanguage(..)
    , MultiLgWord
    , gtxt
    , gtxt_
    )

import Dict exposing (Dict)
import Html exposing (Html, text)


type DisplayLanguage
    = DisplayPortuguese
    | DisplayEnglish


type alias MultiLgWord =
    { portuguese : String
    , english : String
    }


gtxt : String -> DisplayLanguage -> String
gtxt theStr language =
    let
        dExpressions =
            Dict.fromList
                [ ( "league", MultiLgWord "Liga" "League" )
                , ( "season", MultiLgWord "Época" "season" )
                , ( "week nr", MultiLgWord "jornada" "week nr" )
                , ( "output mode", MultiLgWord "visualizar" "output" )
                , ( "football Standings", MultiLgWord "Classificação" "Football Standings" )
                , ( "standings", MultiLgWord "Classificação" "Standings" )
                , ( "yes", MultiLgWord "sim" "yes" )
                , ( "no", MultiLgWord "não" "no" )
                , ( "table size", MultiLgWord "tabela" "table size" )
                , ( "full", MultiLgWord "total" "full" )
                , ( "partial", MultiLgWord "parcial" "partial" )
                , ( "_Standings-Season_", MultiLgWord "Classificação - Época - " "Standings  - Season -" )
                , ( "_Pos_", MultiLgWord "Pos." "Pos." )
                , ( "_Equipas_", MultiLgWord "Equipas" "Teams" )
                , ( "_Total_", MultiLgWord "Total" "Total" )
                , ( "_Casa_", MultiLgWord "Casa" "Home" )
                , ( "_Fora_", MultiLgWord "Fora" "Away" )
                , ( "_Pts_", MultiLgWord "Pts." "Pts." )
                , ( "_Jg_", MultiLgWord "Jg" "Gp" )
                , ( "_V_", MultiLgWord "V" "W" )
                , ( "_E_", MultiLgWord "E" "D" )
                , ( "_D_", MultiLgWord "D" "L" )
                , ( "_GM_", MultiLgWord "GM" "GF" )
                , ( "_GS_", MultiLgWord "GS" "GA" )
                , ( "show goals", MultiLgWord "mostrar golos" "show goals" )
                , ( "football Calendar", MultiLgWord "Calendário" "Football Calendar" )
                , ( "calendar", MultiLgWord "Calendário" "Calendar" )
                , ( "all weeks", MultiLgWord "todas as semanas" "all weeks" )
                , ( "single week", MultiLgWord "uma semana" "single week" )
                , ( "_Week_", MultiLgWord "Jornada" "Week" )
                ]

        mbMatch =
            Dict.get theStr dExpressions

        outStr =
            case mbMatch of
                Nothing ->
                    ""

                Just wordrec ->
                    case language of
                        DisplayPortuguese ->
                            wordrec.portuguese

                        DisplayEnglish ->
                            wordrec.english

        --_ =
        --    Debug.log "translated word is " outStr
    in
    outStr


gtxt_ : String -> DisplayLanguage -> Html msg
gtxt_ theStr language =
    text (gtxt theStr language)
