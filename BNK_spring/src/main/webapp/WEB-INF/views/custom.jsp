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
  </style>
</head>
<body>
  <button id="addTextBtn">텍스트 추가</button>

  <div class="card" id="card">
    <img src="/image/CARD 1.png" class="bg" />
  </div>

  <script src="https://cdn.jsdelivr.net/npm/interactjs/dist/interact.min.js"></script>
  <script>
    let count = 0;

    document.getElementById('addTextBtn').addEventListener('click', () => {
      const card = document.getElementById('card');
      const newText = document.createElement('div');
      newText.className = 'text-box';
      newText.innerText = '새 텍스트 ' + (++count);
      newText.setAttribute('data-x', 0);
      newText.setAttribute('data-y', 0);
      newText.style.transform = 'translate(0px, 0px)';
      card.appendChild(newText);

      makeDraggable(newText);

      newText.addEventListener('click', (e) => {
        e.stopPropagation();

        // ✅ 모든 텍스트에서 기존 X버튼 제거
        document.querySelectorAll('.text-box .close-btn').forEach(btn => btn.remove());

        // ✅ 현재 요소에만 X 버튼 추가
        const closeBtn = document.createElement('span');
        closeBtn.innerText = '×';
        closeBtn.className = 'close-btn';

        closeBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          newText.remove();
        });

        newText.appendChild(closeBtn);
      });
    });

    function makeDraggable(target) {
      interact(target).draggable({
        listeners: {
          move(event) {
            const target = event.target;
            const x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx;
            const y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy;

            target.style.transform = `translate(\${x}px, \${y}px)`;
            target.setAttribute('data-x', x);
            target.setAttribute('data-y', y);
          }
        }
      });
    }

    // ✅ 카드 영역 클릭 시 모든 X버튼 제거
    document.getElementById('card').addEventListener('click', () => {
      document.querySelectorAll('.text-box .close-btn').forEach(btn => btn.remove());
    });
  </script>
</body>
</html>
