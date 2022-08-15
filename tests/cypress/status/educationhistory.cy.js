const host = 'https://educationhistory.lib.unb.ca'
describe('History of Education in New Brunswick', {baseUrl: host, groups: ['sites']}, () => {

  context('Front page', {baseUrl: host}, () => {
    beforeEach(() => {
      cy.visit('/')
      cy.title()
        .should('contain', 'History of Education in New Brunswick')
    })

    specify('Downloadable PDF/ePub documents, "Embeded Issuu" should be available', () => {
      cy.get('.content a[href="/sites/default/files/2016-07/education_history.pdf"]')
        .should('be.visible')
      cy.get('.content a[href="/sites/default/files/2016-07/education_history.epub"]')
        .should('be.visible')
      cy.getEmbededIssuu().within(() => {
        cy.get('.reader')
          .should('be.visible')
      })
    })
  })

})
