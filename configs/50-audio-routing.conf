monitor.alsa.rules = [
  {
    matches = [
      { node.name = "~alsa_output.*sof-nau8821-max.*Speaker*" }
    ]
    actions = {
      update-props = {
        priority.session = 100
        node.description = "Speakers (Raw - Do Not Use)"
      }
    }
  }
]
