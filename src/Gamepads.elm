port module Gamepads exposing
    ( Model, init
    , Msg, update, subscriptions
    , Gamepad, get
    , Buttons, Joysticks, Axis
    )

{-|

@docs Model, init
@docs Msg, update, subscriptions
@docs Gamepad, get
@docs Buttons, Joysticks, Axis

-}

import Dict exposing (Dict)
import Json.Decode


type Model
    = Model
        { gamepads : Dict Int Gamepad
        }


type alias Gamepad =
    { index : Int
    , buttons : Buttons
    , joysticks : Joysticks
    }


type alias Buttons =
    { a : Bool, b : Bool, x : Bool, y : Bool }


type alias Joysticks =
    { left : Axis, right : Axis }


type alias Axis =
    { x : Float
    , y : Float
    }


get : Int -> Model -> Maybe Gamepad
get index (Model { gamepads }) =
    Dict.get index gamepads


init : Model
init =
    Model
        { gamepads = Dict.empty
        }


type Msg
    = GamepadsUpdated (Dict Int Gamepad)
    | GamepadsDataFailedToDecode Json.Decode.Error


update : Msg -> Model -> Model
update msg (Model model) =
    case msg of
        GamepadsUpdated gamepads ->
            Model { model | gamepads = gamepads }

        GamepadsDataFailedToDecode reason ->
            let
                _ =
                    Debug.log "json" reason
            in
            Model model


port gamepadUpdated : (Json.Decode.Value -> msg) -> Sub msg


subscriptions : (Msg -> outerMsg) -> Model -> Sub outerMsg
subscriptions toMsg model =
    gamepadUpdated (onGamepadUpdated >> toMsg)


onGamepadUpdated : Json.Decode.Value -> Msg
onGamepadUpdated json =
    case Json.Decode.decodeValue decoder json of
        Ok gamepads ->
            GamepadsUpdated gamepads

        Err reason ->
            GamepadsDataFailedToDecode reason


decoder : Json.Decode.Decoder (Dict Int Gamepad)
decoder =
    Json.Decode.list (Json.Decode.maybe maybeGamepadDecoder)
        |> Json.Decode.map filterDisconnectedGamepads
        |> Json.Decode.map Dict.fromList


maybeGamepadDecoder : Json.Decode.Decoder Gamepad
maybeGamepadDecoder =
    Json.Decode.map3 Gamepad
        (Json.Decode.field "index" Json.Decode.int)
        (Json.Decode.field "buttons" buttonsDecoder)
        (Json.Decode.field "joysticks" joysticksDecoder)


buttonsDecoder : Json.Decode.Decoder Buttons
buttonsDecoder =
    Json.Decode.map4 Buttons
        (Json.Decode.field "a" Json.Decode.bool)
        (Json.Decode.field "b" Json.Decode.bool)
        (Json.Decode.field "x" Json.Decode.bool)
        (Json.Decode.field "y" Json.Decode.bool)


joysticksDecoder : Json.Decode.Decoder Joysticks
joysticksDecoder =
    Json.Decode.map2 Joysticks
        (Json.Decode.field "left" axisDecoder)
        (Json.Decode.field "right" axisDecoder)


axisDecoder : Json.Decode.Decoder Axis
axisDecoder =
    Json.Decode.map2 Axis
        (Json.Decode.field "x" Json.Decode.float)
        (Json.Decode.field "y" Json.Decode.float)


filterDisconnectedGamepads : List (Maybe Gamepad) -> List ( Int, Gamepad )
filterDisconnectedGamepads maybeGamepads =
    maybeGamepads
        |> List.filterMap
            (\maybeGamepad ->
                case maybeGamepad of
                    Just gamepad ->
                        Just ( gamepad.index, gamepad )

                    Nothing ->
                        Nothing
            )
