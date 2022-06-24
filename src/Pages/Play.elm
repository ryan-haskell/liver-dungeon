port module Pages.Play exposing (Model, Msg, page)

import Browser.Events
import ElmLand.Page exposing (Page)
import Gamepads exposing (Gamepad)
import Html exposing (Html)
import Html.Attributes as Attr
import View exposing (View)


port onGameReady : () -> Cmd msg


page : Page Model Msg
page =
    ElmLand.Page.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { gamepads : Gamepads.Model
    , players : Players
    }


type alias Players =
    { red : Position
    , yellow : Position
    , green : Position
    , blue : Position
    }


type alias Position =
    { x : Float
    , y : Float
    , direction : Direction
    }


type Direction
    = Left
    | Right


init : ( Model, Cmd Msg )
init =
    ( { gamepads = Gamepads.init
      , players =
            { red = { x = 50, y = 50, direction = Left }
            , blue = { x = 150, y = 50, direction = Left }
            , yellow = { x = 150, y = 150, direction = Left }
            , green = { x = 50, y = 150, direction = Left }
            }
      }
    , onGameReady ()
    )



-- UPDATE


type Msg
    = GamepadSentMsg Gamepads.Msg
    | Tick Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GamepadSentMsg innerMsg ->
            ( { model | gamepads = Gamepads.update innerMsg model.gamepads }
            , Cmd.none
            )

        Tick msElapsed ->
            ( { model | players = updatePlayers msElapsed model }
            , Cmd.none
            )


updatePlayers : Float -> Model -> Players
updatePlayers msElapsed model =
    let
        speed =
            0.25

        updatePositionFromGamepad : Int -> Position -> Position
        updatePositionFromGamepad index position =
            case Gamepads.get index model.gamepads of
                Just gamepad ->
                    { x = position.x + speed * msElapsed * gamepad.joysticks.left.x
                    , y = position.y + speed * msElapsed * gamepad.joysticks.left.y
                    , direction =
                        if gamepad.joysticks.left.x > 0 then
                            Right

                        else if gamepad.joysticks.left.x < 0 then
                            Left

                        else
                            position.direction
                    }

                Nothing ->
                    position
    in
    { red = updatePositionFromGamepad 0 model.players.red
    , yellow = updatePositionFromGamepad 1 model.players.yellow
    , green = updatePositionFromGamepad 2 model.players.green
    , blue = updatePositionFromGamepad 3 model.players.blue
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta Tick
        , Gamepads.subscriptions GamepadSentMsg model.gamepads
        ]



-- VIEW


type Player
    = Red
    | Blue
    | Yellow
    | Green


view : Model -> View Msg
view model =
    { title = "Pages.Play"
    , body =
        [ Html.div [ Attr.class "game" ]
            ([ Red, Blue, Yellow, Green ]
                |> List.indexedMap (viewPlayerSquare model)
            )

        -- , Html.text (Debug.toString model.gamepads)
        ]
    }


viewPlayerSquare : Model -> Int -> Player -> Html Msg
viewPlayerSquare model index player =
    let
        position : Position
        position =
            toPlayerPosition model player
    in
    Html.div
        [ Attr.classList
            [ ( "square", True )
            , ( toPlayerSquareClassname player, True )
            , ( "square--right", position.direction == Right )
            ]
        , Attr.style "top" (px position.y)
        , Attr.style "left" (px position.x)
        ]
        []


px : Float -> String
px num =
    String.fromFloat num ++ "px"


toPlayerSquareClassname : Player -> String
toPlayerSquareClassname player =
    case player of
        Red ->
            "square--red"

        Blue ->
            "square--blue"

        Yellow ->
            "square--yellow"

        Green ->
            "square--green"


toPlayerPosition : Model -> Player -> Position
toPlayerPosition model player =
    case player of
        Red ->
            model.players.red

        Blue ->
            model.players.blue

        Yellow ->
            model.players.yellow

        Green ->
            model.players.green
