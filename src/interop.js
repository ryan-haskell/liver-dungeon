let listener = undefined

export const onReady = ({ app }) => {
  if (app.ports && app.ports.onGameReady) {
    app.ports.onGameReady.subscribe((msg) => {
      console.log("On game ready!")
      if (app.ports.gamepadUpdated) {
        listener =
          listener || window.requestAnimationFrame(pollGamepadState(app))
      }
    })
  }
}

let last = undefined

const pollGamepadState = (app) => () => {
  let gamepads = window.navigator.getGamepads()
  let data = gamepads.map((gamepad, index) => {
    if (gamepad) {
      return {
        index: index,
        buttons: {
          a: gamepad.buttons[0].pressed,
          b: gamepad.buttons[1].pressed,
          x: gamepad.buttons[2].pressed,
          y: gamepad.buttons[3].pressed,
        },
        joysticks: {
          left: { x: gamepad.axes[0], y: gamepad.axes[1] },
          right: { x: gamepad.axes[2], y: gamepad.axes[3] },
        },
      }
    } else {
      return null
    }
  })
  let stringified = JSON.stringify(data)
  if (stringified !== last) {
    last = stringified
    app.ports.gamepadUpdated.send(data)
  }

  listener = window.requestAnimationFrame(pollGamepadState(app))
}
