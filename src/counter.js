fetch('https://stagingapi.kgmy.at/updateVisitors')
  .then(response => response.json())
  .then(data => {
    const viewsCount = data.views.N;
    document.getElementById('view-counter').innerText = `${viewsCount} views`;
  })
  .catch(error => console.error(error));