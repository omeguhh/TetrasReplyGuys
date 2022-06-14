//SPDX-License-Identifier: MIT
/**
@title Tetra's Reply Guys
@dev We are creating a simple site to allow Tetra's reply guys to pay a minimum fee, or bid higher to ask Tetra questions.
 */

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ReplyGuy {

    address payable owner;
    uint256 minQuestionPrice = 0.2 ether;

    using Counters for Counters.Counter;
    Counters.Counter private _questionIds;

    enum q_Status {open, closed}

    q_Status currentStatus;

    struct Question {
        uint256 qId;
        uint256 pricePaid;
        string title;
        string body;
        address _replyGuy;
        bool published;
        q_Status status;
        string answer; 
    }

    mapping(address => bool) private paidViewer;
    mapping(address => Question) private replyGuyQuestions;
    mapping(uint => Question) private idToQuestion;
    // mapping(uint => Answer) private idToAnswer;
    mapping(string => Question) private hashToPost;

    event QuestionCreated(uint id, string title, string hash);

    receive() external payable {}

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        msg.sender == owner;
        paidViewer[msg.sender] = true;
        _;
    }

    modifier authorizedViewer {
        require(paidViewer[msg.sender] == true);
        _;     
    }

    function createQuestion(string memory title, string memory hash) public payable {
        require(msg.value >= minQuestionPrice, "Value must be at least minimum asking price.");
        _questionIds.increment();
        uint questionId = _questionIds.current();
        Question storage question = idToQuestion[questionId];
        question.qId = questionId;
        question.pricePaid = msg.value;
        question.title = title;
        question.published = true;
        question.body = hash;
        question._replyGuy = msg.sender;
        question.status =  q_Status.open;
        hashToPost[hash] = question;

        paidViewer[msg.sender] = true;

        payable(this).transfer(question.pricePaid);
        emit QuestionCreated(questionId, title, hash);
    }

    function getMinQuestionPrice() public view returns (uint256) {
        return minQuestionPrice;
    }

    function getUnansweredQuestions() public onlyOwner returns(Question[] memory) {
        uint questionCount = _questionIds.current();

        Question[] memory questions = new Question[](questionCount);
        for (uint i =0; i<questionCount; i++) {
            uint currentId = i+1;
            Question storage currentQuestion = idToQuestion[currentId];
            questions[i] = currentQuestion;
        }
        return questions;
    }

    function answerQuestion(uint256 questionId, string memory hash) public onlyOwner payable {
        Question storage currentQuestion = idToQuestion[questionId];
        currentQuestion.answer = hash;
        currentQuestion.status = q_Status.closed;

        payable(msg.sender).transfer(currentQuestion.pricePaid);
    }

    function fetchQuestions() public view authorizedViewer returns (Question[] memory) {
        //require(currentStatus == q_Status.closed);
        uint questionCount = _questionIds.current();

        Question[] memory questions = new Question[](questionCount);
        for (uint i =0; i<questionCount; i++) {
            uint currentId = i+1;
            Question storage currentQuestion = idToQuestion[currentId];
            questions[i] = currentQuestion;
        }
        return questions;

    }

    // function fetchAnswers() public view returns (Answer[] memory) {
    //      uint answerCount = _answerIds.current();

    //     Answer[] memory answers = new Answer[](answerCount);
    //     for (uint i =0; i<answerCount; i++) {
    //         uint currentId = i+1;
    //         Answer storage currentAnswer = idToAnswer[currentId];
    //         answers[i] = currentAnswer;
    //     }
    //     return answers;
    // }
}
