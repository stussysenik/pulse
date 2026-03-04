export const ConfettiListener = {
  mounted() {
    this.el.addEventListener("pulse:confetti", () => {
      const output = this.el.querySelector("#confetti-output")
      const emojis = ["\u2728", "\u2B50", "\u26A1", "\u2764\uFE0F", "\u2705", "\u2728", "\u2B50", "\u26A1"]
      let confetti = ""
      for (let i = 0; i < 20; i++) {
        confetti += emojis[Math.floor(Math.random() * emojis.length)]
      }
      if (output) output.textContent = confetti
      setTimeout(() => {
        if (output) output.textContent = "Custom event dispatched and caught by hook!"
      }, 2000)
    })
  }
}
