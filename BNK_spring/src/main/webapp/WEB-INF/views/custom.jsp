<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <title>커스텀 카드 에디터</title>
  <style>
    body {
      font-family: sans-serif;
      padding: 20px;
    }

    .card {
      position: relative;
      width: 400px;
      height: 250px;
      margin-top: 20px;
      border-radius: 16px;
      border: 1px solid #ccc;
    }

    .bg {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }

    .text-box {
      position: absolute;
      font-size: 20px;
      color: black;
      font-weight: bold;
      cursor: move;
      user-select: none;
      transform: translate(0px, 0px);
    }

    .close-btn {
      position: absolute;
      top: -10px;
      right: -10px;
      background: red;
      color: white;
      border-radius: 50%;
      padding: 2px 5px;
      cursor: pointer;
      font-size: 14px;
      z-index: 10;
    }
    .rotate-btn {
	    position: absolute;
	    top: -10px;
	    left: -10px;
	    background: #555;
	    color: white;
	    border-radius: 50%;
	    padding: 2px 5px;
	    cursor: grab;
	    font-size: 12px;
	    z-index: 10;
	    user-select: none;
	  }
  </style>
</head>
<body>
  	<button id="addTextBtn">텍스트 추가</button>
	<button id="increaseFont">폰트 +</button>
	<button id="decreaseFont">폰트 -</button>
  <div class="card" id="card">
    <img src="/image/CARD 1.png" class="bg" />
  </div>

<script src="https://cdn.jsdelivr.net/npm/interactjs/dist/interact.min.js"></script>
<script>
  let count = 0;
  let selectedTextBox = null;

  document.getElementById('addTextBtn').addEventListener('click', () => {
    const card = document.getElementById('card');
    const newText = document.createElement('div');
    newText.className = 'text-box';
    newText.innerText = '새 텍스트 ' + (++count);
    newText.setAttribute('data-x', 0);
    newText.setAttribute('data-y', 0);
    newText.setAttribute('data-rotate', 0);
    newText.style.transform = 'translate(0px, 0px) rotate(0deg)';
    card.appendChild(newText);

    makeDraggable(newText);
    enableEditing(newText);
    enableTextBoxInteraction(newText);
  });

  function makeDraggable(target) {
    interact(target).draggable({
      listeners: {
        move(event) {
          const target = event.target;
          const x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx;
          const y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy;
          const angle = parseFloat(target.getAttribute('data-rotate')) || 0;

          target.style.transform = `translate(\${x}px, \${y}px) rotate(\${angle}deg)`;
          target.setAttribute('data-x', x);
          target.setAttribute('data-y', y);
        }
      }
    });
  }

  function enableEditing(textBox) {
    textBox.addEventListener('dblclick', () => {
      textBox.setAttribute('contenteditable', 'true');
      textBox.focus();
      textBox.addEventListener('blur', () => {
        textBox.removeAttribute('contenteditable');
      }, { once: true });
    });
  }

  function enableTextBoxInteraction(textBox) {
    textBox.addEventListener('click', (e) => {
      e.stopPropagation();
      selectedTextBox = textBox;

      // 기존 버튼 제거
      document.querySelectorAll('.text-box .close-btn').forEach(btn => btn.remove());
      document.querySelectorAll('.text-box .rotate-btn').forEach(btn => btn.remove());

      // X 버튼 생성
      const closeBtn = document.createElement('span');
      closeBtn.innerText = '×';
      closeBtn.className = 'close-btn';
      closeBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        textBox.remove();
        selectedTextBox = null;
      });
      textBox.appendChild(closeBtn);

      // 회전 버튼 생성
      const rotateBtn = document.createElement('span');
      rotateBtn.innerText = '⟳';
      rotateBtn.className = 'rotate-btn';
      textBox.appendChild(rotateBtn);

      let isRotating = false;

      rotateBtn.addEventListener('mousedown', (e) => {
        e.stopPropagation();
        isRotating = true;

        const rect = textBox.getBoundingClientRect();
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;

        function onMouseMove(eMove) {
          if (!isRotating) return;
          const dx = eMove.clientX - centerX;
          const dy = eMove.clientY - centerY;
          const angle = Math.atan2(dy, dx) * (180 / Math.PI);

          const x = parseFloat(textBox.getAttribute('data-x')) || 0;
          const y = parseFloat(textBox.getAttribute('data-y')) || 0;

          textBox.style.transform = `translate(\${x}px, \${y}px) rotate(\${angle}deg)`;
          textBox.setAttribute('data-rotate', angle);
        }

        function onMouseUp() {
          isRotating = false;
          window.removeEventListener('mousemove', onMouseMove);
          window.removeEventListener('mouseup', onMouseUp);
        }

        window.addEventListener('mousemove', onMouseMove);
        window.addEventListener('mouseup', onMouseUp);
      });
    });
  }

  // 카드 영역 클릭 시 모든 버튼 제거
  document.getElementById('card').addEventListener('click', () => {
    document.querySelectorAll('.text-box .close-btn').forEach(btn => btn.remove());
    document.querySelectorAll('.text-box .rotate-btn').forEach(btn => btn.remove());
    selectedTextBox = null;
  });

  // 폰트 크기 증가
  document.getElementById('increaseFont').addEventListener('click', () => {
    if (selectedTextBox) {
      const currentSize = parseInt(window.getComputedStyle(selectedTextBox).fontSize);
      selectedTextBox.style.fontSize = (currentSize + 2) + 'px';
    }
  });

  // 폰트 크기 감소
  document.getElementById('decreaseFont').addEventListener('click', () => {
    if (selectedTextBox) {
      const currentSize = parseInt(window.getComputedStyle(selectedTextBox).fontSize);
      selectedTextBox.style.fontSize = Math.max(10, currentSize - 2) + 'px';
    }
  });
</script>


</body>
</html>
