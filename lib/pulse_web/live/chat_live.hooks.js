export const AutoScroll = {
  mounted() {
    this.scrollToBottom()
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.el, { childList: true })
  },
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight
  },
  destroyed() {
    if (this.observer) this.observer.disconnect()
  }
}
