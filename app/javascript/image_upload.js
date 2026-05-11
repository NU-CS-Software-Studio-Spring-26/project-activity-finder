document.addEventListener("turbo:load", () => {
  setupNewImageUpload();
  setupExistingImageReorder();
});

function activityImagePreviewAlt() {
  const titleInput = document.querySelector('input[name="activity[title]"]');
  const title = titleInput?.value?.trim();
  return title || "Activity image";
}

function refreshNewImagePreviewAlts() {
  const alt = activityImagePreviewAlt();
  document.querySelectorAll(".new-image-item img").forEach((img) => {
    img.alt = alt;
  });
}

function setupNewImageUpload() {
  const input = document.getElementById("activity-images-input");
  const dropZone = document.getElementById("drop-zone");
  const previewList = document.getElementById("image-preview-list");

  if (!input || !dropZone || !previewList) return;

  const titleInput = document.querySelector('input[name="activity[title]"]');
  titleInput?.addEventListener("input", refreshNewImagePreviewAlts);

  let files = [];

  dropZone.addEventListener("click", () => input.click());

  dropZone.addEventListener("dragover", (event) => {
    event.preventDefault();
    dropZone.classList.add("drag-over");
  });

  dropZone.addEventListener("dragleave", () => {
    dropZone.classList.remove("drag-over");
  });

  dropZone.addEventListener("drop", (event) => {
    event.preventDefault();
    dropZone.classList.remove("drag-over");
    addFiles(Array.from(event.dataTransfer.files));
  });

  input.addEventListener("change", () => {
    addFiles(Array.from(input.files));
  });

  function addFiles(newFiles) {
    const imageFiles = newFiles.filter((file) => file.type.startsWith("image/"));

    files = [...files, ...imageFiles].slice(0, 10);

    updateInputFiles();
    renderPreviews();
  }

  function renderPreviews() {
    previewList.innerHTML = "";

    files.forEach((file, index) => {
      const reader = new FileReader();

      reader.onload = (event) => {
        const item = document.createElement("div");
        item.className = "image-preview-item new-image-item";
        item.draggable = true;
        item.dataset.index = String(index);

        const badge = document.createElement("div");
        badge.className = "thumbnail-badge";
        badge.textContent = String(index + 1);

        const img = document.createElement("img");
        img.src = event.target.result;
        img.alt = activityImagePreviewAlt();

        const nameDiv = document.createElement("div");
        nameDiv.className = "image-name";
        nameDiv.textContent = file.name;

        item.appendChild(badge);
        item.appendChild(img);
        item.appendChild(nameDiv);

        item.addEventListener("dragstart", handleDragStart);
        item.addEventListener("dragover", handleDragOver);
        item.addEventListener("drop", handleDrop);

        previewList.appendChild(item);
      };

      reader.readAsDataURL(file);
    });
  }

  let draggedIndex = null;

  function handleDragStart(event) {
    draggedIndex = Number(event.currentTarget.dataset.index);
  }

  function handleDragOver(event) {
    event.preventDefault();
  }

  function handleDrop(event) {
    event.preventDefault();

    const droppedIndex = Number(event.currentTarget.dataset.index);

    if (draggedIndex === null || draggedIndex === droppedIndex) return;

    const draggedFile = files.splice(draggedIndex, 1)[0];
    files.splice(droppedIndex, 0, draggedFile);

    draggedIndex = null;

    updateInputFiles();
    renderPreviews();
  }

  function updateInputFiles() {
    const dataTransfer = new DataTransfer();

    files.forEach((file) => dataTransfer.items.add(file));

    input.files = dataTransfer.files;
  }
}

function setupExistingImageReorder() {
  const list = document.getElementById("existing-image-list");
  if (!list) return;

  let draggedItem = null;

  list.querySelectorAll(".existing-image-item").forEach((item) => {
    item.addEventListener("dragstart", () => {
      draggedItem = item;
      item.classList.add("dragging");
    });

    item.addEventListener("dragend", () => {
      item.classList.remove("dragging");
      draggedItem = null;
      updateExistingImageOrder();
    });

    item.addEventListener("dragover", (event) => {
      event.preventDefault();

      const target = event.currentTarget;
      if (!draggedItem || draggedItem === target) return;

      const bounding = target.getBoundingClientRect();
      const offset = event.clientY - bounding.top;

      if (offset > bounding.height / 2) {
        target.after(draggedItem);
      } else {
        target.before(draggedItem);
      }
    });
  });

  function updateExistingImageOrder() {
    list.querySelectorAll(".existing-image-item").forEach((item) => {
      const input = item.querySelector(".image-order-input");
      input.value = item.dataset.id;
    });
  }
}