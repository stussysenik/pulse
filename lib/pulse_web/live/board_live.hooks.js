import Sortable from "@/vendor/sortable.min.js"

export const SortableHook = {
  mounted() {
    new Sortable(this.el, {
      group: "board",
      animation: 150,
      ghostClass: "opacity-30",
      dragClass: "rotate-2",
      onEnd: (evt) => {
        this.pushEvent("card_dropped", {
          id: evt.item.dataset.id,
          column: evt.to.dataset.column,
          index: evt.newIndex
        })
      }
    })
  }
}
