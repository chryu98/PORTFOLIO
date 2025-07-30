<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>커스텀 카드 에디터</title>
  <style>
  	*{
  		margin:0;
  		padding:0;
  	}
    body {
      font-family: sans-serif;
    }

    .card {
	  width: 250px;
	  aspect-ratio: 3 / 5;
	  background-size: 100%;
	  background-repeat: no-repeat;
	  background-position: 50% 50%;
	  
	  border: 1px solid #ccc;
	  overflow: hidden;
	  position: relative;
	  touch-action: none; /* 모바일 터치 방지 */
	  user-select: none;
	  cursor: grab;
	}


    .text-box {
    	touch-action: none;
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
  #bgImg {
	  position: absolute;
	  top: 0;
	  left: 0;
	  transform-origin: center center;
	  object-fit: cover;
	  pointer-events: none; /* 드래그 이벤트가 텍스트 등에만 전달되도록 */
	}
  </style>
</head>
<body>
  	<button id="addTextBtn">텍스트 추가</button>
	<button id="increaseFont">A+</button>
	<button id="decreaseFont">A-</button>
	<input type="color" id="fontColorPicker" value="#000000">
	<input type="file" id="cardBgInput" accept="image/*" />
	<button id="zoomIn">확대</button>
	<button id="zoomOut">축소</button>
	<button id="reset">초기화</button>
	<label>회전: <input type="range" id="rotateRange" min="-180" max="180" value="0" /></label>
		
  <div class="card" id="card">
  	<img id="bgImg" />
  </div>

<script src="https://cdn.jsdelivr.net/npm/interactjs/dist/interact.min.js"></script>
<script>
  let count = 0;
  let selectedTextBox = null;
  let bgRotate = 0; // 배경 회전각
  let bgScale = 1;
  
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
	  touchAction: 'none',
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
	  let touchTimer = null;

	  // 모바일: 길게 누르면 수정모드
	  textBox.addEventListener('touchstart', () => {
	    touchTimer = setTimeout(() => {
	      textBox.setAttribute('contenteditable', 'true');
	      textBox.focus();
	    }, 500); // 500ms 이상 누르면 수정 모드
	  });

	  textBox.addEventListener('touchend', () => {
	    clearTimeout(touchTimer);
	  });

	  // 데스크탑: 더블클릭
	  textBox.addEventListener('dblclick', () => {
	    textBox.setAttribute('contenteditable', 'true');
	    textBox.focus();
	  });

	  // 포커스 잃었을 때 저장
	  textBox.addEventListener('blur', () => {
	    textBox.removeAttribute('contenteditable');
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

      rotateBtn.addEventListener('pointerdown', (e) => {
        e.stopPropagation();
        e.preventDefault();
        isRotating = true;

        const rect = textBox.getBoundingClientRect();
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;

        function onPointerMove(eMove) {
          if (!isRotating) return;
          const dx = eMove.clientX - centerX;
          const dy = eMove.clientY - centerY;
          const angle = Math.atan2(dy, dx) * (180 / Math.PI);

          const x = parseFloat(textBox.getAttribute('data-x')) || 0;
          const y = parseFloat(textBox.getAttribute('data-y')) || 0;

          textBox.style.transform = `translate(\${x}px, \${y}px) rotate(\${angle}deg)`;
          textBox.setAttribute('data-rotate', angle);
        }

        function onPointerUp() {
          isRotating = false;
          window.removeEventListener('pointermove', onPointerMove);
          window.removeEventListener('pointerup', onPointerUp);
        }

        window.addEventListener('pointermove', onPointerMove);
        window.addEventListener('pointerup', onPointerUp);
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
  //글자 색상 변경
  document.getElementById('fontColorPicker').addEventListener('input', (e) => {
    if (selectedTextBox) {
	      selectedTextBox.style.color = e.target.value;
    }
  });
  
  //배경이미지 삽입
  document.getElementById('cardBgInput').addEventListener('change', function (e) {
	  const file = e.target.files[0];
	  if (!file) return;

	  const reader = new FileReader();
	  reader.onload = function (event) {
	    const bgUrl = event.target.result;
	  };
	  reader.readAsDataURL(file);
	});
  
  //배경 이미지 위치조정
  const card = document.getElementById('card');
const fileInput = document.getElementById('cardBgInput');
const zoomInBtn = document.getElementById('zoomIn');
const zoomOutBtn = document.getElementById('zoomOut');
const resetBtn = document.getElementById('reset');

let bgPos = { x: 0, y: 0 }; // 초기 background-position
let bgSize = 100; // 초기 background-size (%)
let isDragging = false;
let start = { x: 0, y: 0 };

// 이미지 업로드
fileInput.addEventListener('change', (e) => {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (event) => {
	  document.getElementById('bgImg').src = event.target.result;
  };
  reader.readAsDataURL(file);
});

// 드래그 시작
card.addEventListener('mousedown', (e) => {
	if (e.target.closest('.text-box')) return;
  isDragging = true;
  start.x = e.clientX;
  start.y = e.clientY;
  card.style.cursor = 'grabbing';
});

document.addEventListener('mousemove', (e) => {
  if (!isDragging) return;

  const dx = e.clientX - start.x;
  const dy = e.clientY - start.y;

  bgPos.x += dx / card.offsetWidth * 100;
  bgPos.y += dy / card.offsetHeight * 100;


  updateBgTransform();

  start.x = e.clientX;
  start.y = e.clientY;
});

document.addEventListener('mouseup', () => {
  isDragging = false;
  card.style.cursor = 'grab';
});

// 확대/축소
zoomInBtn.addEventListener('pointerup', () => {
  bgScale = Math.min(3, bgScale + 0.1);
  updateBgTransform();
});

zoomOutBtn.addEventListener('pointerup', () => {
  bgScale = Math.max(0.3, bgScale - 0.1);
  updateBgTransform();
});

// 초기화
resetBtn.addEventListener('click', () => {
  bgPos = { x: 0, y: 0 };
  bgSize = 100;
  updateBgTransform();
});

// 적용 함수
function updateBgTransform() {
  bgImg.style.transform = `
    translate(\${bgPos.x}px, \${bgPos.y}px)
    scale(\${bgScale})
    rotate(\${bgRotate}deg)
  `;
}

//모바일 터치 시작
card.addEventListener('touchstart', (e) => {
	if (e.target.closest('.text-box')) return; // 텍스트박스 터치면 배경 드래그 무시
  if (e.touches.length !== 1) return; // 멀티터치 방지
  isDragging = true;
  start.x = e.touches[0].clientX;
  start.y = e.touches[0].clientY;
  card.style.cursor = 'grabbing';
}, { passive: false });

// 모바일 터치 이동
document.addEventListener('touchmove', (e) => {
  if (!isDragging || e.touches.length !== 1) return;

  const dx = e.touches[0].clientX - start.x;
  const dy = e.touches[0].clientY - start.y;

  bgPos.x += dx / card.offsetWidth * 100;
  bgPos.y += dy / card.offsetHeight * 100;

  /* bgPos.x = Math.max(0, Math.min(100, bgPos.x));
  bgPos.y = Math.max(0, Math.min(100, bgPos.y)); */

  updateBgTransform();

  start.x = e.touches[0].clientX;
  start.y = e.touches[0].clientY;
}, { passive: false });

// 모바일 터치 끝
document.addEventListener('touchend', () => {
  isDragging = false;
  card.style.cursor = 'grab';
});
//이미지회전
const rotateRange = document.getElementById('rotateRange');

rotateRange.addEventListener('input', (e) => {
  bgRotate = parseInt(e.target.value, 10);
  updateBgTransform();
});

resetBtn.addEventListener('click', () => {
	  bgPos = { x: 0, y: 0 };
	  bgSize = 100;
	  bgRotate = 0;
	  rotateRange.value = 0; // 슬라이더도 초기화
	  updateBgTransform();
	});
</script>


</body>
</html>
