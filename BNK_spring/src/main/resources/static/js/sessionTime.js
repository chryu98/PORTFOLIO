document.addEventListener("DOMContentLoaded", () => {
	const timer = document.getElementById("session-timer");
	if (!timer) return; // 요소가 없으면 실행 중단

	function formatTime(sec){
		const min = Math.floor(sec / 60);
		const secVal = sec % 60;
		const minStr = min < 10 ? "0" + min : "" + min;
		const secStr = secVal < 10 ? "0" + secVal : "" + secVal;
		return minStr + ":" + secStr;
	}

	function updateTimer(){
		if (remainingSeconds <= 0) {
			timer.textContent = "00:00";
			clearInterval(timerInterval);
			location.href = "/logout?expired=true";
			return;
		}
		timer.textContent = formatTime(remainingSeconds);
		remainingSeconds--;
	}

	let remainingSeconds = 1200;
	let timerInterval = setInterval(updateTimer, 1000);
	updateTimer();

	window.extend = function(){
		fetch("/session/keep-session", {
			method: "POST"
		})
		.then(res => res.json())
		.then(data => {
			if (data.remainingSeconds) {
				remainingSeconds = data.remainingSeconds;
				updateTimer();
			}
		});
	};

	window.logout = async function() {
		if (confirm("로그아웃 하시겠습니까?")) {
			try {
				const response = await fetch("/user/api/logout", {
					method: "POST"
				});

				const result = await response.json();

				if (response.ok) {
					// 서버 세션 로그아웃 후 JWT 제거
					localStorage.removeItem("jwtToken");
					localStorage.removeItem("memberNo"); // 필요 시 제거
									
					alert(result.message);
					location.href = "/";
				} else {
					alert("로그아웃 실패");
				}
			} catch (error) {
				console.error("로그아웃 오류:", error);
				alert("오류가 발생했습니다.");
			}
		}
	};
});
