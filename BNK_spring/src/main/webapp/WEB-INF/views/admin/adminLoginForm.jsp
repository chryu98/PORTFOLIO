<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>관리자 로그인</title>

<style>

body {
	background-color: #f9f9f9;
}

.login-wrapper {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
}

/* 로그인 컨테이너 */
.login-container {
   display: flex;
   align-items: center;     /* 수직 가운데 */
justify-content: center; /* 수평 가운데 */
    max-width: 400px;
    width: 100%;
    margin: 60px auto;
    padding: 40px 30px;
    background: #ffffff;
    border-radius: 12px;
    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    transition: transform 0.3s ease, box-shadow 0.3s ease;
}
.login-container:hover {
    transform: translateY(-4px);
    box-shadow: 0 6px 24px rgba(0,0,0,0.15);
}

/* 제목 */
.login-container h2 {
    text-align: center;
    margin-bottom: 28px;
    font-size: 1.8rem;
    color: #2c3e50;
    font-weight: 600;
}

/* 폼 */
.login-container form {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

/* 입력창 */
.login-container input {
    width: 85%;
    padding: 14px 18px;
    border: 1px solid #ddd;
    border-radius: 6px;
    font-size: 1rem;
    transition: border-color 0.3s, box-shadow 0.3s;
}
.login-container input:focus {
    border-color: #3498db;
    box-shadow: 0 0 0 3px rgba(52,152,219,0.2);
    outline: none;
}

/* 버튼 */
.login-container button {
    padding: 14px;
    background: #3498db;
    color: #fff;
    font-size: 1rem;
    font-weight: 600;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    transition: background 0.3s, transform 0.2s;
}
.login-container button:hover {
    background: #2980b9;
    transform: translateY(-2px);
}
.login-container button:active {
    background: #2471a3;
}


</style>
</head>


<body>


<div class="login-wrapper">
  <div class="login-container">
     
      <form id="loginForm">
       <h2>관리자 로그인</h2>
         <input type="text" id="username" placeholder="아이디" required autocomplete="off">
<input type="password" id="password" placeholder="비밀번호" required autocomplete="off">
          <button type="submit">로그인</button>
      </form>
  </div>
</div>

<script>
document.getElementById("loginForm").addEventListener("submit", function(e) {
    e.preventDefault();

    const data = {
        username: document.getElementById("username").value,
        password: document.getElementById("password").value
    };

    fetch("/admin/login", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(data)
    })
    .then(response => {
        if (!response.ok) {
            return response.json().then(err => {throw err;});
        }
        return response.json();
    })
    .then(result => {
        if (result.success) {
            alert(result.message);
            // 로그인 성공 시 관리자 메인 페이지로 이동
            window.location.href = "/admin/CardList";
        } else {
          
        }
    })
    .catch(error => {
       
        
    });
});
</script>
</body>
</html>