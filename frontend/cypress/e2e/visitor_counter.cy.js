describe('View counter', () => {
  it('displays an increasing number of view on reload', () => {
    cy.visit(Cypress.env('site_url'))
    cy.wait(1000)
    cy.get('p#view-counter')
      .invoke('text')
      .then((text) => {
        const viewCount = parseInt(text.replace(/views/, ''))
        expect(text).to.match(/^\d+\s+view(s)?$/)
        expect(viewCount).to.be.a('number')

        cy.reload(true)
        cy.wait(3000)

        cy.get('p#view-counter')
          .invoke('text')
          .then((text) => {
            const newViewCount = parseInt(text.replace(/views/, ''))
            expect(text).to.match(/^\d+\s+view(s)?$/)
            expect(newViewCount).to.be.a('number')
            expect(viewCount).to.be.lessThan(newViewCount)
        })
      })
    })
})
