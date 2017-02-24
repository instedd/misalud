function initLinechart() {
  var container = $(".linechart");
  if (container.size() == 0) return;
  var linechart = new Linechart($("svg", container)[0]);
  function resize(e) {
    linechart.setSize(container.innerWidth(), container.innerWidth() / 2);
    linechart.render();
  }

  linechart.data(container.data());
  resize();

  window.addEventListener("resize", resize);
}

function initDonut() {
  var container = $(".donut");
  if (container.size() == 0) return;
  var donut = new Donut($("svg", container)[0], 3);
  function resize(e) {
    donut.setSize(container.innerWidth(), container.innerWidth());
    donut.render();
  }

  donut.data(container.data().d);
  resize();

  window.addEventListener("resize", resize);
}

$(function(){
  initLinechart();
  initDonut();
});
