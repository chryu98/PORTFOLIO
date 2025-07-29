document.querySelector(".header-close-btn").addEventListener("click",function(){
	document.querySelector(".sidebar").classList.add("closed");
	document.querySelector(".header-close-btn").classList.add("off")
})
document.querySelector(".header-open-btn").addEventListener("click",function(){
	document.querySelector(".sidebar").classList.remove("closed");
	document.querySelector(".header-close-btn").classList.remove("off")
})

document.getElementById("logoutBtn").addEventListener("click", function() {
    if (!confirm("로그아웃 하시겠습니까?")) return;

    fetch("/admin/logout", {
        method: "POST",
        credentials: "include" // 세션 쿠키 포함
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            alert(result.message);
            window.location.href = "/admin/adminLoginForm"; // 로그인 페이지로 이동
        } else {
            alert(result.message);
        }
    })
    .catch(error => {
        alert("로그아웃 오류: " + (error.message || "서버 오류"));
        console.error(error);
    });
});