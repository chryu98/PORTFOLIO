<%@ page contentType="text/html; charset=UTF-8" %>
<html>
<head>
    <title>부산은행 챗봇</title>
    <script>
        function askBot() {
            var q = document.getElementById("question").value;

            fetch("http://localhost:8000/ask", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({ question: q })
            })
            .then(response => response.json())
            .then(data => {
                document.getElementById("answer").innerText = data.answer;
            })
            .catch(error => {
                console.error("Error:", error);
                document.getElementById("answer").innerText = "서버 오류가 발생했습니다.";
            });
        }
    </script>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <h2>부산은행 챗봇</h2>
    <input type="text" id="question" placeholder="질문을 입력하세요" size="50"/>
    <button onclick="askBot()">질문하기</button>
    <hr/>
    <h3>챗봇 답변:</h3>
    <div id="answer" style="white-space: pre-line; border:1px solid #ccc; padding:10px; min-height:50px;"></div>
</body>

</html>
