<exercise-section>
<div class="box">
<div class="level">
     <div class="level-right">
      <span class="level-item" >
      <span class="icon is-small moveHandle"><i class="fa fa-bars" aria-hidden="true"></i></span>
      </span>
      <a class="level-item" onclick={ editExercise }>
      <span class="icon is-small has-text-info"><i class="fas fa-pencil-alt" aria-hidden="true"></i></span>
      </a>
      <a class="level-item" onclick={ removeExercise }>
      <span class="icon is-small has-text-danger"><i class="fas fa-trash-alt" aria-hidden="true"></i></span>
      </a>
      </div>
     </div>
     <div class="exercise"><p id="{ questionId }" class="previewText"></p></div>
     <br/>
     <div class="exercise"><p id="{ answerId }" class="previewText"></p></div>
</div>
<!--  MODAL TO EDIT EXERCISE  -->
<div class="modal {is-active: showModal}">
  <div class="modal-background"></div>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title">Edit Exercise</p>
      <button class="delete" aria-label="close" onclick={ close }></button>
    </header>
    <section class="modal-card-body">
      <div class="field">
        <div class="control">
          <a class="button" onclick={ showChartModal }>Insert Chart</a>
        </div>
      </div>
      <div class="field">
        <div class="control">
          <input type="text" id="{ editQuestionId }" class="input mathContent" placeholder="edit exercise question"/>
       </div>
      </div>
      <div class="field">
        <div class="control">
          <textarea id="{ editAnswerId }" class="textarea mathContent" placeholder="edit exercise answer"></textarea>
        </div>
        <br/>
        <div class="control">
        <label>Question Preview</label>
          <div class="box">
            <p id='{ editQuestionTextId }' class="previewText"></p>
          </div>
        </div>
        <div class="control">
        <label>Answer Preview</label>
          <div class="box">
            <p id='{ editAnswerTextId }' class="previewText"></p>
          </div>
        </div>
      </div>
    </section>
    <footer class="modal-card-foot">
      <button class="button is-success" onclick={ saveChanges }>Save changes</button>
      <button class="button" onclick={ close }>Cancel</button>
      <p class="help has-text-grey">Remember to Save Tutorial State after you save your changes.</p>
    </footer>
  </div>
</div>
<script>

var self = this
this.showModal = false
this.clientId = this.opts.id
this.exerciseObservable = this.opts.exerciseObservable
this.chartObservable = this.opts.chartObservable
// generate Id's
this.answerId = 'answer_' + this.opts.id
this.questionId = 'question_' + this.opts.id

this.editQuestionId = 'editQuestion_' + this.opts.id
this.editQuestionTextId = 'editQuestionText_' + this.opts.id

this.editAnswerId = 'editAnswer_' + this.opts.id
this.editAnswerTextId = 'editAnswerText_' + this.opts.id

this.chartList = this.opts.chartList

this.on('mount', function() {
  this.exerciseObservable.trigger('createdExercise', this.opts.id, this)
  self.bindExerciseValues()
  // preview question text
  self.$('editQuestionId').on('input', debounce(self.renderQuestionPreview));

  // preview answer text
  self.$('editAnswerId').on('input', debounce(self.renderAnswerPreview));

  this.exerciseObservable.on('renderCharts', function() {
    self.renderCharts(self.chartList)
  })

  self.opts.exerciseObservable.on('deletedExercise', function(exerciseId, exerciseIndex) {
      if(exerciseIndex < self.opts.exerciseIndex){
       self.opts.exerciseIndex -= 1

      }
  })

  self.opts.exerciseObservable.on('exerciseOrderUpdate', function(oldIndex, newIndex){
    if (oldIndex === self.opts.exerciseIndex){
      self.opts.exerciseIndex = newIndex
      return
    }

    // an exercise was moved up the list
    if (oldIndex > newIndex && newIndex <= self.opts.exerciseIndex && oldIndex > self.opts.exerciseIndex){
      self.opts.exerciseIndex += 1
    }
    // an exercise was moved down the list
    else if (oldIndex < newIndex && newIndex >= self.opts.exerciseIndex && oldIndex < self.opts.exerciseIndex){
      self.opts.exerciseIndex -= 1
    } 

  })


  this.chartObservable.on('savedChart', function(clientId, chartSize, chartData, chartOptions) {

    if (clientId !== self.clientId){
      return
    }

    const newChartId = uniqueId()
    
    const currentQuestion = self.$('editQuestionId').val()
    const appendDiv = '<div id="'+newChartId+'" class="ct-chart '+chartSize+'"></div>'
    self.$('editQuestionId').val(currentQuestion + ' ' + appendDiv)
    self.chartList.push({ id: newChartId, data: chartData, options: chartOptions })
    self.$('editQuestionId').trigger('input')
  })
  
})

renderQuestionPreview(){
  const questionVal = self.$('editQuestionId').val()
  self.$('editQuestionTextId').html(questionVal)
  self.render(self.editQuestionTextId)
  self.renderEditModalCharts(self.chartList)
}

renderAnswerPreview(){
  const answerVal = self.$('editAnswerId').val()
  self.$('editAnswerTextId').html(answerVal)
  self.render(self.editAnswerTextId)
  self.renderEditModalCharts(self.chartList)
}
bindExerciseValues(){
  this.$('questionId').html(this.opts.question)
  this.$('answerId').html(this.opts.answer)
  self.render(self.questionId)
  self.render(self.answerId)
  self.renderCharts(self.chartList)
}

editExercise(){
  this.showModal = true
  // when the modal opens, we want the question and answer values to carry over
  this.$('editQuestionId').val(this.opts.question)
  this.$('editQuestionTextId').html(this.opts.question)
  self.render(this.editQuestionTextId)

  this.$('editAnswerId').val(this.opts.answer)
  this.$('editAnswerTextId').html(this.opts.answer)
  self.render(this.editAnswerTextId)

  self.renderEditModalCharts(this.chartList)
}

saveChanges(){
  var confirmChanges = confirm('Would you like to confirm these changes ?')
  if (confirmChanges){
    this.updateExercise()
    const showPrompt = false
    Messenger.send(MessageTopic.TutorialUpdated)
    this.closeModal(showPrompt)
  }
}

updateExercise(){
    this.opts.question = this.$('editQuestionId').val()
    this.opts.questionText = this.$('editQuestionTextId').html()

    this.opts.answer = this.$('editAnswerId').val()
    this.opts.answerText = this.$('editAnswerTextId').html()

    this.opts.chartList = this.chartList

    this.$('questionId').html(this.opts.questionText)
    this.$('answerId').html(this.opts.answerText)
}

close(){
  const showPrompt = true
  this.closeModal(showPrompt)
}

closeModal(showPrompt){
  if (showPrompt){
    var confirmClose = confirm('Are you sure you want to close this edit view ? Any unsaved changes will be discarded.')
    if (confirmClose){
      this.showModal = false
    }
  }
  else{
    this.showModal = false
  }
}

removeExercise(){
  var confirmChanges = confirm('Are you sure you want to delete the chosen exercise ?')
  if (confirmChanges){
    this.opts.exerciseObservable.trigger('deletedExercise', this.opts.id, this.opts.exerciseIndex)
    Messenger.send(MessageTopic.TutorialUpdated)
    this.unmount(true)
    $(this.opts.id).remove()
  }
}

get(){
  return {
    id: this.opts.id,
    question: this.opts.question,
    answer: this.opts.answer,
    exerciseIndex: this.opts.exerciseIndex,
    chartList: this.opts.chartList
  }
}

showChartModal(){
    this.chartObservable.trigger('showChartModal', self.clientId)
}

render(id){
  try{
    renderMathInElement(document.getElementById(id))
  }
  catch(err){
  }
}

// used when exercise is created and fully loaded
renderCharts(chartList) {
  for (var i in chartList) {
      const chart = chartList[i]
      const questionSelector = $('#'+this.questionId+'> #'+chart.id).get(0)
      if (questionSelector){
        createLineChart(questionSelector, chart.data, chart.options)
      }
      const answerSelector = $('#'+this.answerId+'> #'+chart.id).get(0)
      if (answerSelector){
        createLineChart(answerSelector, chart.data, chart.options)
      }
    }
}

// used to re-render charts during editing process
renderEditModalCharts(chartList) {
    for (var i in chartList) {
      const chart = chartList[i]
      const questionSelector = $('#'+ self.editQuestionTextId +'> #'+chart.id).get(0)
      if (questionSelector){
        createLineChart(questionSelector, chart.data, chart.options)
      }
      const answerSelector = $('#'+ self.editAnswerTextId +'> #'+chart.id).get(0)
      if (answerSelector){
        createLineChart(answerSelector, chart.data, chart.options)
      }
    }
}

// jquery alias
$(val){
  return $('#'+this[val])
}
</script>
</exercise-section>