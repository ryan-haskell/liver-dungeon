module Pages.Home_ exposing (page)

import Html exposing (..)
import Html.Attributes as Attr
import View exposing (View)


page : View msg
page =
    { title = "Homepage"
    , body =
        [ h1 [] [ text "Liver Dungeon" ]
        , h3 [] [ text "Ummmmm... rich!" ]
        , a [ Attr.href "/play" ] [ text "Start game" ]
        ]
    }
